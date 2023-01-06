/* Bomberman Battles map script
By Meryilla

Yes, this script could do with more comments. Yes, the custom classes could've been split into their own files. Yes, the script is amateurish. 
But it works and I'm a lazy individual, so it's good enough for me :^)
*/
	
const string g_szBombModel1 = "models/bman/bomb_small_b.mdl";
const string g_szBombModel2 = "models/bman/bomb_med_b.mdl";
const string g_szBombModel3 = "models/bman/bomb_large_b.mdl";
const string g_szAntiDelayBombModel = "models/bman/bomb_antidelay_a.mdl";
const string g_szBronzeBombModel = "models/bman/bomb_bronze_a.mdl";
const string g_szSilverBombModel = "models/bman/bomb_silver_a.mdl";
const string g_szGoldBombModel = "models/bman/bomb_gold_a.mdl";

const string g_szWhitePlayerModel = "models/player/bman_white/bman_white.mdl";
const string g_szPinkPlayerModel = "models/player/bman_pink/bman_pink.mdl";
const string g_szBlackPlayerModel = "models/player/bman_black/bman_black.mdl";

const string g_szScreamSound = "bman/aaaa.wav";

const string g_szBombGibModel = "models/metalplategibs_dark.mdl";
const string g_szExplosionSprite = "sprites/rc/rc_explosion2HD.spr";

const float g_flCrateHealth = 50;
const int g_iExplodeDamage = 50;

//If this is enabled, players are slayed/refused play if they are using annoying player models
const bool blAntiCancerEnabled = true;

int g_iActivePlayerCount = 0;

array<float> g_flPlayerScores;
array<float> g_flSortedPlayerScores;

EHandle g_hThirdPlayer, g_hSecondPlayer, g_hFirstPlayer;
CCVar cvarAltBombSolidLogic( "altbombsolidlogic", 0, "Enable alternative bomb solid logic", ConCommandFlag::AdminOnly );
	
array<string> 	DeathSoundEvents = {
				"weapons/explode3.wav",
				"weapons/explode4.wav",
				"weapons/explode5.wav"
};	

array<string> 	CrateDeathSoundEvents = {
				"debris/bustcrate1.wav",
				"debris/bustcrate2.wav",
				"debris/bustcrate3.wav"
};

//Add substrings to the array below for the anti-cancer system to slay players using models containing said substring
array<string>	CancerModels = {
	
	"shit", "invisible", "meatwall", "garg", "snarkgarg", "fockewulftriebflugel", "mbt", "apachef"
	
};


void MapInit()
{
	g_Hooks.RegisterHook( Hooks::Player::PlayerUse, PlantBomb );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, SetPlayerValues );
	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, SetPlayerSpeed );
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, TakeDamage );
	g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, PoisonThink );
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, PlayerKilled );
	g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, PlayerDisconnected );
	
	g_CustomEntityFuncs.RegisterCustomEntity( "CFuncBomb", "func_bomb" );
	g_CustomEntityFuncs.RegisterCustomEntity( "CFuncCrate", "func_crate" );
	g_CustomEntityFuncs.RegisterCustomEntity( "CPowerupBomb", "func_powerup_bomb" );
	g_CustomEntityFuncs.RegisterCustomEntity( "CPowerupLife", "func_powerup_life" );
	g_CustomEntityFuncs.RegisterCustomEntity( "CPowerupFire", "func_powerup_fire" );
	g_CustomEntityFuncs.RegisterCustomEntity( "CPowerupSkate", "func_powerup_skate" );
	g_CustomEntityFuncs.RegisterCustomEntity( "CPowerupSkull", "func_powerup_skull" );
	
	g_flPlayerScores.resize( 0 );
	g_flPlayerScores.resize( 33 );
	
	g_flSortedPlayerScores.resize( 0 );
	g_flSortedPlayerScores.resize( 33 );
	
	Precache();
	
	if( blAntiCancerEnabled )
		g_Scheduler.SetInterval( "AntiCancerDetection", 3.0f, g_Scheduler.REPEAT_INFINITE_TIMES );
}

void Precache()
{
	g_Game.PrecacheModel( g_szBombModel1 );
	g_Game.PrecacheModel( g_szBombModel2 );
	g_Game.PrecacheModel( g_szBombModel3 );
	g_Game.PrecacheModel( g_szBronzeBombModel );
	g_Game.PrecacheModel( g_szSilverBombModel );
	g_Game.PrecacheModel( g_szGoldBombModel );
	g_Game.PrecacheModel( g_szAntiDelayBombModel );
	
	g_Game.PrecacheModel( g_szWhitePlayerModel );
	g_Game.PrecacheModel( g_szPinkPlayerModel );
	g_Game.PrecacheModel( g_szBlackPlayerModel );
	
	g_Game.PrecacheModel( g_szBombGibModel );
	g_Game.PrecacheModel( g_szExplosionSprite );
	g_Game.PrecacheModel( "sprites/poison.spr" );
	
	g_Game.PrecacheModel( "sprites/bman/bonus_life.spr" );
	g_Game.PrecacheModel( "sprites/bman/bonus_bomb2.spr" );
	g_Game.PrecacheModel( "sprites/bman/bonus_bomb3.spr" );
	
	g_SoundSystem.PrecacheSound( "weapons/explode3.wav" );
	g_SoundSystem.PrecacheSound( "weapons/explode4.wav" );
	g_SoundSystem.PrecacheSound( "weapons/explode5.wav" );	
	
	g_SoundSystem.PrecacheSound( g_szScreamSound );

	g_Game.PrecacheModel( "models/woodgibs.mdl" );
	
	g_SoundSystem.PrecacheSound( "debris/bustcrate1.wav" );
	g_SoundSystem.PrecacheSound( "debris/bustcrate2.wav" );
	g_SoundSystem.PrecacheSound( "debris/bustcrate3.wav" );	
}

HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
	if( kvPlayer !is null )
	{
		if( kvPlayer.GetKeyvalue( "$i_activePlayer" ).GetInteger() == 1 )
		{
			//Figure if the player was one of the last 3 survivors at death
			if( g_iActivePlayerCount == 3 )
				g_hThirdPlayer = EHandle( pPlayer );
			else if( g_iActivePlayerCount == 2 )
				g_hSecondPlayer = EHandle( pPlayer );
			else if( g_iActivePlayerCount == 1 )
				g_hFirstPlayer = EHandle ( pPlayer );
			
			g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_activePlayer", "0" );
			g_iActivePlayerCount--;
		}
		if( kvPlayer.GetKeyvalue( "$i_poisoned" ).GetInteger() == 1 )
			ClearPoison( pPlayer );
	}

	return HOOK_CONTINUE;
}

HookReturnCode PlayerDisconnected( CBasePlayer@ pPlayer )
{
	pPlayer.pev.frags = 0;
	int iPlayerIndex = pPlayer.entindex();	
	g_flPlayerScores[iPlayerIndex] = 0;
	
	CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
	if( kvPlayer !is null || kvPlayer.HasKeyvalue( "$i_activePlayer" ) )
	{
		if( kvPlayer.GetKeyvalue( "$i_activePlayer" ).GetInteger() == 1 )
		{
			g_iActivePlayerCount--;
		}
	}
	
	return HOOK_CONTINUE;
}

HookReturnCode PoisonThink( CBasePlayer@ pPlayer )
{
	if( pPlayer is null )
		return HOOK_CONTINUE;
	
	CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
	
	if( kvPlayer !is null and kvPlayer.GetKeyvalue( "$i_poisonType" ).GetInteger() == 4 )
	{
		CreateBomb( pPlayer );
		CBaseEntity@ pSound = g_EntityFuncs.FindEntityByTargetname( pSound, "" + pPlayer.pev.targetname + "_scream" );
		if( pSound !is null )
			pSound.SetOrigin( pPlayer.GetOrigin() );
	}
	
	if( kvPlayer.GetKeyvalue( "$i_poisoned" ).GetInteger() == 1 )
	{
		CBaseEntity@ pOther;
		//Transfer poison to players in touch radius
		while( ( @pOther = g_EntityFuncs.FindEntityInSphere( pOther, pPlayer.pev.origin, 40 , "player", "classname" ) ) !is null )
		{
			if( pOther !is null && pOther.IsPlayer() && pOther !is pPlayer)
			{
				CBasePlayer@ pOtherPlayer = cast<CBasePlayer@>( pOther );
				CustomKeyvalues@ kvOtherPlayer = pOtherPlayer.GetCustomKeyvalues();
				if( kvOtherPlayer !is null && ( g_Engine.time > kvOtherPlayer.GetKeyvalue( "$f_recentlyPoisoned" ).GetFloat() ) && kvOtherPlayer.GetKeyvalue( "$i_poisoned" ).GetInteger() == 0 )
				{
					g_EntityFuncs.DispatchKeyValue( pOtherPlayer.edict(), "$i_poisoned", "1" );
					int iPoisonType = kvPlayer.GetKeyvalue( "$i_poisonType" ).GetInteger();
					switch( iPoisonType )
					{
						case 0:					
							pOtherPlayer.SetMaxSpeed( 80 );
							g_EntityFuncs.DispatchKeyValue( pOtherPlayer.edict(), "$i_poisonType", string( iPoisonType ) );
							g_EngineFuncs.ClientPrintf( pOtherPlayer, print_center, "TOO SLOW!\n" );
							break;
							
						case 1:
							pOtherPlayer.SetMaxSpeed( 800 );
							g_EntityFuncs.DispatchKeyValue( pOtherPlayer.edict(), "$i_poisonType", string( iPoisonType ) );
							g_EngineFuncs.ClientPrintf( pOtherPlayer, print_center, "TOO FAST!\n" );
							break;
							
						case 2:
							g_EntityFuncs.DispatchKeyValue( pOtherPlayer.edict(), "$i_poisonType", string( iPoisonType ) );
							g_EngineFuncs.ClientPrintf( pOtherPlayer, print_center, "CONSTIPATED!\n" );
							break;
							
						case 3:
							g_EntityFuncs.DispatchKeyValue( pOtherPlayer.edict(), "$i_poisonType", string( iPoisonType ) );
							g_EngineFuncs.ClientPrintf( pOtherPlayer, print_center, "WEAK BOMBS!\n" );
							break;
							
						case 4:
							CreateScream( pOtherPlayer );
							g_EntityFuncs.DispatchKeyValue( pOtherPlayer.edict(), "$i_poisonType", string( iPoisonType ) );
							g_EngineFuncs.ClientPrintf( pOtherPlayer, print_center, "DIARRHEA!\n" );	
							break;
					}
					AttachPoisonSprite( pOtherPlayer );
					ClearPoison( pPlayer );
					g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$f_recentlyPoisoned", string( g_Engine.time + 3.0f ) );
				}
			}
		}
	}
	return HOOK_CONTINUE;
}

HookReturnCode SetPlayerSpeed( CBasePlayer@ pPlayer )
{
	if( pPlayer is null )
		return HOOK_CONTINUE;
	
	pPlayer.SetMaxSpeed( 200 );
	return HOOK_CONTINUE;
	
}

HookReturnCode TakeDamage( DamageInfo@ pDamageInfo )
{
	if( pDamageInfo is null || pDamageInfo.pVictim is null )
		return HOOK_CONTINUE;
	
	CustomKeyvalues@ kvPlayer = pDamageInfo.pVictim.GetCustomKeyvalues();
	edict_t@ pEdict;
	CBaseEntity@ pEntity;
	
	if( kvPlayer !is null || kvPlayer.HasKeyvalue( "$s_hasLifeSprite" ) )
	{
		if( kvPlayer.GetKeyvalue( "$s_hasLifeSprite" ).GetString() == "1" )
		{
			for( int pIndex = 0; pIndex < g_Engine.maxEntities; ++pIndex )
			{
				@pEdict = @g_EntityFuncs.IndexEnt( pIndex );
				@pEntity = g_EntityFuncs.Instance( pEdict );
				
				if( pEntity !is null )
					if( pEntity.pev.targetname == "" + pDamageInfo.pVictim.pev.targetname + "_attachSprite" || pEntity.pev.targetname == "" + pDamageInfo.pVictim.pev.targetname + "_bonusLifeSprite" )
						g_EntityFuncs.Remove( pEntity );
			}
			g_EntityFuncs.DispatchKeyValue( pDamageInfo.pVictim.edict(), "$s_hasLifeSprite", "0" );
			return HOOK_CONTINUE;
		}
	}
	
	return HOOK_CONTINUE;
}

HookReturnCode SetPlayerValues( CBasePlayer@ pPlayer )
{
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_maxBombCount", "1" );
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_bombCount", "0" );
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$s_hasLifeSprite", "0" );
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$s_hasBombSprite", "0" );
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_ownBombStrength", "1" );
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisoned", "0" );
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisonType", "0" );
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$f_recentlyPoisoned", "0" );
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$s_hasPoisonSprite", "0" );
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_activePlayer", "0" );
	
	pPlayer.pev.frags = 0;
	int iPlayerIndex = pPlayer.entindex();
	g_flPlayerScores[iPlayerIndex] = 0;
	return HOOK_CONTINUE;
}

void ClearPlayerKeyValues( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	CBaseEntity@ pEntity;
	while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "player" ) ) !is null )
	{
		if( pEntity !is null && pEntity.IsPlayer() )
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pEntity );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_maxBombCount", "1" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_bombCount", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$s_hasLifeSprite", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$s_hasBombSprite", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_ownBombStrength", "1" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_poisoned", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_poisonType", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$s_hasPoisonSprite", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_activePlayer", "0" );
			pPlayer.pev.targetname = "";
			pPlayer.pev.health = 50;
			pPlayer.SetMaxSpeed( 200 );
		}
	}
	g_iActivePlayerCount = 0;
}

HookReturnCode PlantBomb( CBasePlayer@ pPlayer, uint& out uiFlags )	
{
	if( ( pPlayer.m_afButtonReleased & IN_USE ) != 0 )
	{
		CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
		if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) || pPlayer.pev.FlagBitSet( FL_INWATER ) )
			return HOOK_CONTINUE;
		
		if( kvPlayer !is null && kvPlayer.GetKeyvalue( "$i_poisonType" ).GetInteger() == 2 )
		{
			g_EngineFuncs.ClientPrintf( pPlayer, print_center, "Cannot place bombs whilst constipated!\n" );
			return HOOK_CONTINUE;
		}
		CreateBomb( pPlayer );
	}
	return HOOK_CONTINUE;	
}

void AssignPlayerSpawns( CBaseEntity@, CBaseEntity@, USE_TYPE, float )
{
	int iPlayerCount = 1;
	CBasePlayer@ pPlayer;
	bool blCancerModel = false;
	
	//Find 16 players at most to spawn and assign them a spawnpoint each
	while( ( @pPlayer = cast<CBasePlayer@>( g_EntityFuncs.FindEntityByClassname( pPlayer, "player" ) ) ) !is null )
	{
		if( pPlayer is null || !pPlayer.IsConnected() )
			continue;
		
		KeyValueBuffer@ pInfo = g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() );
		
		//If Anti-Cancer is enabled, ban players with shitty player models from playing
		if( blAntiCancerEnabled )
		{
			for( uint i = 0; i < CancerModels.length(); i++ )
			{
				if( pInfo.GetValue( "model" ).Find( CancerModels[i], 0 ) != String::INVALID_INDEX )
					blCancerModel = true;
			}
			
			if( blCancerModel )
			{
				g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiCancer] " + pPlayer.pev.netname + " was barred from playing for using a cancerous model!\n");
				blCancerModel = false;
			}
			else
			{
				pPlayer.pev.targetname = string( iPlayerCount );
				iPlayerCount++;
				if( iPlayerCount > 16 )
				{
					g_PlayerFuncs.SayText( pPlayer, "[Map] " + "There are >16 players and you were not picked to play, sorry!\n" );
				}
				else
				{
					g_iActivePlayerCount = iPlayerCount - 1;				
					g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_activePlayer", "1" );
				}
			}		
		}
		else
		{
			pPlayer.pev.targetname = string( iPlayerCount );
			iPlayerCount++;
			if( iPlayerCount > 16 )
			{
				g_PlayerFuncs.SayText( pPlayer, "[Map] " + "There are >16 players and you were not picked to play, sorry!\n" );
			}
			else
			{
				g_iActivePlayerCount = iPlayerCount - 1;				
				g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_activePlayer", "1" );
			}
		}
	}
	
	return;	
}

void UpdateScoresDraw( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	CBasePlayer@ pFirstPlayer, pSecondPlayer, pThirdPlayer;
	
	@pFirstPlayer = cast<CBasePlayer@>( g_hFirstPlayer.GetEntity() );
	@pSecondPlayer = cast<CBasePlayer@>( g_hSecondPlayer.GetEntity() );
	@pThirdPlayer = cast<CBasePlayer@>( g_hThirdPlayer.GetEntity() );
	
	//We only give 25 points in a draw, to discourage players from playing for a draw instead of going for the win
	if( pFirstPlayer !is null )
		pFirstPlayer.pev.frags += 25;
	
	if( pSecondPlayer !is null )
		pSecondPlayer.pev.frags += 25;

	if( pThirdPlayer !is null )
		pThirdPlayer.pev.frags += 25;

	SortScores();	

	SortScores();
}

void UpdateScoresWin( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	CBasePlayer@ pSecondPlayer, pThirdPlayer;
	
	@pSecondPlayer = cast<CBasePlayer@>( g_hSecondPlayer.GetEntity() );
	@pThirdPlayer = cast<CBasePlayer@>( g_hThirdPlayer.GetEntity() );
	
	if( pSecondPlayer !is null )
		pSecondPlayer.pev.frags += 50;

	if( pThirdPlayer !is null )
		pThirdPlayer.pev.frags += 25;

	SortScores();
}

void SortScores()
{
	int iPlayerIndex;
	CBasePlayer@ pPlayer;
	while( ( @pPlayer = cast<CBasePlayer@>( g_EntityFuncs.FindEntityByClassname( pPlayer, "player" ) ) ) !is null )
	{
		if( pPlayer is null )
			continue;		
		
		iPlayerIndex = pPlayer.entindex();
		g_flPlayerScores[iPlayerIndex] = pPlayer.pev.frags;
	}
	
	g_flSortedPlayerScores = g_flPlayerScores;
	g_flSortedPlayerScores.sortDesc();	

}

void SelectWinners( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	CBasePlayer@ pGoldPlayer, pSilverPlayer, pBronzePlayer;
	float flGoldScore, flSilverScore, flBronzeScore;
	bool blGoldFound, blSilverFound, blBronzeFound;
	blGoldFound = blSilverFound = blBronzeFound = false;
	
	
	g_flSortedPlayerScores = g_flPlayerScores;
	g_flSortedPlayerScores.sortDesc();
	
	flGoldScore = g_flSortedPlayerScores[0];
	flSilverScore = g_flSortedPlayerScores[1];
	flBronzeScore = g_flSortedPlayerScores[2];
	
	for( uint i = 1; i < g_flPlayerScores.length(); i++ )
	{
		if( ( g_flPlayerScores[i] == flGoldScore ) and !blGoldFound )
		{
			@pGoldPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
			blGoldFound = true;
		}
		else if( ( g_flPlayerScores[i] == flSilverScore ) and !blSilverFound )
		{
			@pSilverPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
			blSilverFound = true;			
		}
		else if( ( g_flPlayerScores[i] == flBronzeScore ) and !blBronzeFound )
		{
			@pBronzePlayer = g_PlayerFuncs.FindPlayerByIndex( i );
			blBronzeFound = true;			
		}
	}
	
	if( pGoldPlayer !is null )
		pGoldPlayer.pev.targetname = "first";
	if( pSilverPlayer !is null )
		pSilverPlayer.pev.targetname = "second";
	if( pBronzePlayer !is null )
		pBronzePlayer.pev.targetname = "third";
}

void AntiCancerDetection()
{
	int iPlayerCount = 1;
	CBasePlayer@ pPlayer;
	bool blActiveCancerModel = false;
	
	while( ( @pPlayer = cast<CBasePlayer@>( g_EntityFuncs.FindEntityByClassname( pPlayer, "player" ) ) ) !is null )
	{
		if( pPlayer is null )
			continue;
		
		CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
		KeyValueBuffer@ pInfo = g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() );
		
		if( kvPlayer !is null and kvPlayer.GetKeyvalue( "$i_activePlayer" ).GetInteger() == 1 )
		{
			for( uint i = 0; i < CancerModels.length(); i++ )
			{
				if( pInfo.GetValue( "model" ).Find( CancerModels[i], 0 ) != String::INVALID_INDEX )
				{
					blActiveCancerModel = true;
				}
			}
			if( blActiveCancerModel )
			{
				g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiCancer] " + pPlayer.pev.netname + " was killed for switching to a cancerous model!\n");
				pPlayer.TakeDamage( pPlayer.pev, pPlayer.pev, 10000000, DMG_BLAST );
				blActiveCancerModel = false;
			}
		}	
	}
}

void CreateBomb( EHandle hPlayer )
{
	CBaseEntity@ pBomb;
	CBaseEntity@ pOtherBomb;
	CBaseEntity@ pTile;
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
	CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
	
	if( pPlayer is null || !pPlayer.pev.FlagBitSet( FL_ONGROUND ) || pPlayer.pev.FlagBitSet( FL_INWATER ) || pPlayer.pev.FlagBitSet( FL_DUCKING ) )
		return;
	
	if( !( kvPlayer is null ) and kvPlayer.HasKeyvalue( "$i_bombCount" ) and kvPlayer.HasKeyvalue( "$i_poisonType" ) )
	{
		if( ( kvPlayer.GetKeyvalue( "$i_bombCount" ).GetInteger() >= kvPlayer.GetKeyvalue( "$i_maxBombCount" ).GetInteger() ) and kvPlayer.GetKeyvalue( "$i_poisonType" ).GetInteger() != 4 )
		{
			g_EngineFuncs.ClientPrintf( pPlayer, print_center, "You can't have more than " + kvPlayer.GetKeyvalue( "$i_maxBombCount" ).GetString() + " bomb(s)\n" );
			return;
		}
	}	
	
	@pOtherBomb = g_EntityFuncs.FindEntityInSphere( null, pPlayer.pev.origin - Vector( 0, 0, 32 ), 28 , "func_bomb", "classname" );
	if( pOtherBomb !is null )
	{
		if( kvPlayer.GetKeyvalue( "$i_poisonType" ).GetInteger() != 4 )
			g_EngineFuncs.ClientPrintf( pPlayer, print_center, "There is already a bomb on this tile\n" );
		return;
	}
	
	@pTile = g_EntityFuncs.FindEntityInSphere( null, pPlayer.pev.origin - Vector( 0, 0, 32 ), 28 , "info_tile" );
	if( pTile !is null )
	{
		dictionary bombValues;
		if( kvPlayer.GetKeyvalue( "$i_poisonType" ).GetInteger() == 3 )
		{
			bombValues =
			{
				{ "origin", "" + ( pTile.pev.origin ).ToString() },
				{ "angles", "" + ( Vector( 0, pPlayer.pev.angles.y, 0 ) ).ToString() },
				{ "$i_ownerIndex", "" + pPlayer.entindex() },
				{ "$i_bombStrength", "1" }
			};
		}
		else
		{
			bombValues =
			{
				{ "origin", "" + ( pTile.pev.origin ).ToString() },
				{ "angles", "" + ( Vector( 0, pPlayer.pev.angles.y, 0 ) ).ToString() },
				{ "$i_ownerIndex", "" + pPlayer.entindex() },
				{ "$i_bombStrength", "" + kvPlayer.GetKeyvalue( "$i_ownBombStrength" ).GetString() }
			};
		}

		@pBomb = g_EntityFuncs.CreateEntity( "func_bomb", bombValues, true);
		g_EntityFuncs.SetSize( pBomb.pev, Vector( -20, -20, 0 ), Vector( 20, 20, 50 ) );
		
		pBomb.pev.targetname = "player_bomb_PID" + pPlayer.entindex() + "_EID" + pBomb.entindex();
		
		if( !( kvPlayer is null ) and kvPlayer.HasKeyvalue( "$i_bombCount" ) )
		{
			g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_bombCount", string( kvPlayer.GetKeyvalue( "$i_bombCount" ).GetInteger() + 1 ) );
		}
	}
}

void UnattachBomb( EHandle hPlayer )
{
	if( !hPlayer )
		return;
	
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
	CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
	
	if( kvPlayer is null || !kvPlayer.HasKeyvalue( "$i_bombCount" ) )
		return;
	
	if( kvPlayer.GetKeyvalue( "$i_bombCount" ).GetInteger() == 0 )
		return;
	else
		g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_bombCount", string( kvPlayer.GetKeyvalue( "$i_bombCount" ).GetInteger() - 1 ) );
}

void AttachLifeSprite( EHandle hEntity )
{
	if ( !hEntity )
		return;
	
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hEntity.GetEntity() );
	
	CBaseEntity@ pSprite, pAttach;
	
	dictionary attachValues =
	{
		{ "origin", "" + pPlayer.pev.origin.ToString() },
		{ "targetname", "" + pPlayer.pev.targetname + "bonusLife_attachSprite" },
		{ "target", "" + pPlayer.pev.targetname + "_bonusLifeSprite" },
		{ "offset", "0 0 64" },
		{ "copypointer", "" + pPlayer.pev.targetname },
		{ "spawnflags", "1011" }
	};
	
	@pAttach = g_EntityFuncs.CreateEntity( "trigger_setorigin", attachValues, true );
	
	if( pAttach !is null )
	{
		dictionary sprValues =
		{
			{ "origin", "" + pPlayer.pev.origin.ToString() },
			{ "targetname", "" + pPlayer.pev.targetname + "_bonusLifeSprite" },
			{ "model", "sprites/bman/bonus_life.spr" },
			{ "scale", "0.05" },
			{ "spawnflags", "1" }	
		};
		
		@pSprite = g_EntityFuncs.CreateEntity( "env_sprite", sprValues, true );
		g_EntityFuncs.FireTargets( "" + pPlayer.pev.targetname + "bonusLife_attachSprite", null, null, USE_ON, 0, 0 );
		
		CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
		
		if( kvPlayer !is null )
			g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$s_hasLifeSprite", "1" );
	}
}

void AttachBombSprite( EHandle hEntity )
{
	if ( !hEntity )
		return;
	
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hEntity.GetEntity() );
	CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
	CBaseEntity@ pSprite, pAttach;
	
	if( kvPlayer !is null )
	{
		if( kvPlayer.HasKeyvalue( "$s_hasBombSprite" ) and kvPlayer.GetKeyvalue( "$s_hasBombSprite" ).GetString() == "1" )
		{
			g_EntityFuncs.FireTargets( "" + pPlayer.pev.targetname + "_bonusBombSprite", null, null, USE_KILL, 0, 0 );
			g_EntityFuncs.FireTargets( "" + pPlayer.pev.targetname + "bonusBomb_attachSprite", null, null, USE_OFF, 0, 0 );
			dictionary sprValues =
			{
				{ "origin", "" + pPlayer.pev.origin.ToString() },
				{ "targetname", "" + pPlayer.pev.targetname + "_bonusBombSprite" },
				{ "model", "sprites/bman/bonus_bomb3.spr" },
				{ "scale", "0.05" },
				{ "spawnflags", "1" }	
			};
			
			@pSprite = g_EntityFuncs.CreateEntity( "env_sprite", sprValues, true );
			g_EntityFuncs.FireTargets( "" + pPlayer.pev.targetname + "bonusBomb_attachSprite", null, null, USE_ON, 0, 0 );
			g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$s_hasBombSprite", "2" );
			return;
		}
	}
	
	dictionary attachValues =
	{
		{ "origin", "" + pPlayer.pev.origin.ToString() },
		{ "targetname", "" + pPlayer.pev.targetname + "bonusBomb_attachSprite" },
		{ "target", "" + pPlayer.pev.targetname + "_bonusBombSprite" },
		{ "offset", "0 0 48" },
		{ "copypointer", "" + pPlayer.pev.targetname },
		{ "spawnflags", "1011" }
	};
	
	@pAttach = g_EntityFuncs.CreateEntity( "trigger_setorigin", attachValues, true );
	
	if( pAttach !is null )
	{
		dictionary sprValues =
		{
			{ "origin", "" + pPlayer.pev.origin.ToString() },
			{ "targetname", "" + pPlayer.pev.targetname + "_bonusBombSprite" },
			{ "model", "sprites/bman/bonus_bomb2.spr" },
			{ "scale", "0.05" },
			{ "spawnflags", "1" }	
		};
		
		@pSprite = g_EntityFuncs.CreateEntity( "env_sprite", sprValues, true );
		g_EntityFuncs.FireTargets( "" + pPlayer.pev.targetname + "bonusBomb_attachSprite", null, null, USE_ON, 0, 0 );
		
		if( kvPlayer !is null )
			g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$s_hasBombSprite", "1" );
	}
}

void AttachPoisonSprite( EHandle hEntity )
{
	if ( !hEntity )
		return;
	
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hEntity.GetEntity() );
	
	CBaseEntity@ pSprite, pAttach;
	
	dictionary attachValues =
	{
		{ "origin", "" + pPlayer.pev.origin.ToString() },
		{ "targetname", "" + pPlayer.pev.targetname + "poison_attachSprite" },
		{ "target", "" + pPlayer.pev.targetname + "_poisonSprite" },
		{ "offset", "0 0 -16" },
		{ "copypointer", "" + pPlayer.pev.targetname },
		{ "spawnflags", "1011" }
	};
	
	@pAttach = g_EntityFuncs.CreateEntity( "trigger_setorigin", attachValues, true );
	
	if( pAttach !is null )
	{
		dictionary sprValues =
		{
			{ "origin", "" + pPlayer.pev.origin.ToString() },
			{ "targetname", "" + pPlayer.pev.targetname + "_poisonSprite" },
			{ "model", "sprites/poison.spr" },
			{ "scale", "1.5" },
			{ "rendermode", "5" },
			{ "vp_type", "1" },
			{ "renderamt", "255" },
			{ "framerate", "5" },
			{ "spawnflags", "1" }	
		};
		
		@pSprite = g_EntityFuncs.CreateEntity( "env_sprite", sprValues, true );
		g_EntityFuncs.FireTargets( "" + pPlayer.pev.targetname + "poison_attachSprite", null, null, USE_ON, 0, 0 );
		
		CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
		
		if( kvPlayer !is null )
			g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$s_hasPoisonSprite", "1" );
	}
}

void ClearSprites( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	edict_t@ pEdict;
	CBaseEntity@ pEntity;
	
	for( int pIndex = 0; pIndex < g_Engine.maxEntities; ++pIndex )
	{
		@pEdict = @g_EntityFuncs.IndexEnt( pIndex );
		@pEntity = g_EntityFuncs.Instance( pEdict );
		
		if( pEntity !is null )
		{
			string szTargetname = string( pEntity.pev.targetname );
			if( szTargetname.EndsWith( "_attachSprite" ) || szTargetname.EndsWith( "_bonusLifeSprite" ) || szTargetname.EndsWith( "_bonusBombSprite" ) || szTargetname.EndsWith( "_poisonSprite" ) )
				g_EntityFuncs.Remove( pEntity );
		}
	}
}

void ClearPoison( EHandle hEntity )
{
	if ( !hEntity )
		return;
	
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hEntity.GetEntity() );
	StopScream( pPlayer );
	
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisonType", "0" );
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisoned", "0" );
	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$s_hasPoisonSprite", "0" );
	
	//TODO: Have players return to their previous speed after clearing slow or speed disease, instead of assuming they were at 200 base
	if( pPlayer.GetMaxSpeed() == 80 || pPlayer.GetMaxSpeed() == 800 )
		pPlayer.SetMaxSpeed( 200 );
	
	CBaseEntity@ pPoisonSprite = g_EntityFuncs.FindEntityByTargetname( pPoisonSprite, "" + pPlayer.pev.targetname + "_poisonSprite" );
	CBaseEntity@ pAttachEntity = g_EntityFuncs.FindEntityByTargetname( pAttachEntity, "" + pPlayer.pev.targetname + "poison_attachSprite" );
	
	if( pPoisonSprite !is null )
		g_EntityFuncs.Remove( pPoisonSprite );
	
	if ( pAttachEntity !is null )
		g_EntityFuncs.Remove( pAttachEntity );
}

void CreateScream( EHandle hEntity )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hEntity.GetEntity() );
	dictionary dummyValues =
	{
		{ "origin", "" + pPlayer.pev.origin.ToString() },
		{ "targetname", "" + pPlayer.pev.targetname + "_scream" }
	};
	
	CBaseEntity@ pSound = g_EntityFuncs.CreateEntity( "info_target", dummyValues, true );
	//le funny serious sam reference
	g_SoundSystem.EmitSoundDyn( pSound.edict(), CHAN_STATIC, g_szScreamSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
}

void StopScream( EHandle hEntity )
{
	if ( !hEntity )
		return;
	
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hEntity.GetEntity() );
	CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
	
	if( kvPlayer !is null )
	{
		CBaseEntity@ pSound = g_EntityFuncs.FindEntityByTargetname( pSound, "" + pPlayer.pev.targetname + "_scream" );
		if( pSound !is null )
		{
			g_SoundSystem.StopSound( pSound.edict(), CHAN_STATIC, g_szScreamSound );
			g_EntityFuncs.Remove( pSound );
		}
	}	
}

bool IsOwner( EHandle hEntity, EHandle hPlayer )
{
	if ( !hEntity or !hPlayer)
		return false;
	
	CBaseEntity@ pBomb = cast<CBaseEntity@>( hEntity.GetEntity() );
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
	CustomKeyvalues@ kvBomb = pBomb.GetCustomKeyvalues();

	if( kvBomb !is null and kvBomb.GetKeyvalue( "$i_ownerIndex" ).GetInteger() == pPlayer.entindex() )
	{
		return true;
	}
	else
		return false;
}

class CFuncBomb : ScriptBaseEntity
{
	private float m_flExplodeTime;
	private array<int> m_iPlayersOnBombTile;
	private bool m_blOwnerInTile = true;
	
	void Precache()
	{
		g_Game.PrecacheModel( g_szBombModel1 );
		g_Game.PrecacheModel( g_szBombModel2 );
		g_Game.PrecacheModel( g_szBombModel3 );	
		
		g_Game.PrecacheModel( g_szBombGibModel );
		g_Game.PrecacheModel( g_szExplosionSprite );
		
		g_SoundSystem.PrecacheSound( "weapons/explode3.wav" );
		g_SoundSystem.PrecacheSound( "weapons/explode4.wav" );
		g_SoundSystem.PrecacheSound( "weapons/explode5.wav" );		
	}

	void Spawn()
	{
		Precache();

		self.pev.solid = SOLID_NOT;
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.rendermode = 4;
		self.pev.renderamt = 125;
		self.pev.nextthink = g_Engine.time + 0.2;

		CustomKeyvalues@ kvBomb = self.GetCustomKeyvalues();
		if( kvBomb is null )
			return;
		
		g_EntityFuncs.DispatchKeyValue( self.edict(), "$i_exploding", "0" );
		
		int iBombSize = kvBomb.GetKeyvalue( "$i_bombStrength" ).GetInteger();
		
		if( iBombSize == 3 )
			g_EntityFuncs.SetModel( self, g_szBombModel3 );
		else if( iBombSize == 2 )
			g_EntityFuncs.SetModel( self, g_szBombModel2 );
		else
			g_EntityFuncs.SetModel( self, g_szBombModel1 );
		
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_STREAM, "weapons/xbow_hitbod2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		
		m_flExplodeTime = g_Engine.time + 4;
	}
	
	void Think()
	{
		self.pev.nextthink = g_Engine.time + 0.1;
		
		CBasePlayer@ pPlayerInBomb;
		CBaseEntity@ pTile;
		CBaseEntity@ pEntity;
		CustomKeyvalues@ kvBomb = self.GetCustomKeyvalues();
		
		m_iPlayersOnBombTile.resize(0);
		m_iPlayersOnBombTile.resize(33);
		
		@pPlayerInBomb = cast<CBasePlayer@>( g_EntityFuncs.FindEntityInSphere( null, self.pev.origin + Vector( 0, 0, 36 ), 40 , "player", "classname" ) );
		
		//If alternative solid logic is enabled, bombs go solid the moment the owner leaves the tile (in theory). Works terribly in practice.
		if( cvarAltBombSolidLogic.GetInt() > 0 )
		{
			if( pPlayerInBomb is null or ( pPlayerInBomb.entindex() != kvBomb.GetKeyvalue( "$i_ownerIndex" ).GetInteger() ) )
			{
				self.pev.solid = SOLID_BBOX;
				self.pev.renderamt = 255;				
			}
		}
		else if( pPlayerInBomb is null )
		{
			self.pev.solid = SOLID_BBOX;
			self.pev.renderamt = 255;				
		}
		
		if( g_Engine.time > m_flExplodeTime || ( kvBomb !is null && kvBomb.GetKeyvalue( "$i_exploding" ).GetInteger() == 1 ) )
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_STREAM, DeathSoundEvents[Math.RandomLong( 0, 2 )], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

			if( kvBomb is null )
				return;
			
			int iBombStrength = kvBomb.GetKeyvalue( "$i_bombStrength" ).GetInteger();
			int iX1Block, iX2Block, iY1Block, iY2Block;
			iX1Block = iX2Block = iY1Block = iY2Block = 0;
			
			@pTile = g_EntityFuncs.FindEntityInSphere( null, self.pev.origin, 28 , "info_tile" );
			if( pTile !is null )
			{
				te_explosion( pTile.pev.origin );
				while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, self.pev.origin + Vector( 0, 0, 36 ), 38 , "*", "classname" ) ) !is null )
				{
					if( pEntity is null )
						continue;
					
					pEntity.TakeDamage( self.pev, self.pev, 50, DMG_BLAST );

					if( pEntity.pev.classname == "func_bomb" )
					{
						auto pBomb = cast<CFuncBomb@>( g_EntityFuncs.CastToScriptClass( @pEntity ) );
						CustomKeyvalues@ kvOtherBomb = pEntity.GetCustomKeyvalues();
						if( kvOtherBomb !is null && kvOtherBomb.GetKeyvalue( "$i_exploding" ).GetInteger() == 0 )
						{
							g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_exploding", "1" );
							pBomb.pev.nextthink = g_Engine.time;
						}
					}				
				}
			}
			
			for( int i = 1; i < iBombStrength + 1; i++ )
			{
				@pTile = g_EntityFuncs.FindEntityInSphere( null, self.pev.origin + Vector( i * 64, 0, 0 ), 36 , "info_tile" );
				if( pTile !is null )
				{
					if( iX1Block > 0 )
						break;
					te_explosion( pTile.pev.origin );
					while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pTile.pev.origin + Vector( 0, 0, 36 ), 38 , "*", "classname" ) ) !is null )
					{
						if( pEntity is null )
							continue;
						
						pEntity.TakeDamage( self.pev, self.pev, 50, DMG_BLAST );
						if( pEntity.pev.classname == "func_crate" )
							iX1Block++;
						
						if( pEntity.pev.classname == "func_bomb" )
						{
							auto pBomb = cast<CFuncBomb@>( g_EntityFuncs.CastToScriptClass( @pEntity ) );
							CustomKeyvalues@ kvOtherBomb = pEntity.GetCustomKeyvalues();
							if( kvOtherBomb !is null && kvOtherBomb.GetKeyvalue( "$i_exploding" ).GetInteger() == 0 )
							{
								g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_exploding", "1" );
								pBomb.pev.nextthink = g_Engine.time + 0.2;
							}
						}
					}
				}
				else
					break;
			}
			
			for( int i = 1; i < iBombStrength + 1; i++ )
			{
				@pTile = g_EntityFuncs.FindEntityInSphere( null, self.pev.origin + Vector( i * -64, 0, 0 ), 28 , "info_tile" );
				if( pTile !is null )
				{
					if( iX2Block > 0 )
						break;				
					te_explosion( pTile.pev.origin );
					while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pTile.pev.origin + Vector( 0, 0, 36 ), 38 , "*", "classname" ) ) !is null )
					{
						if( pEntity is null )
							continue;
						
						pEntity.TakeDamage( self.pev, self.pev, 50, DMG_BLAST );
						if( pEntity.pev.classname == "func_crate" )
							iX2Block++;			
						
						if( pEntity.pev.classname == "func_bomb" )
						{
							auto pBomb = cast<CFuncBomb@>( g_EntityFuncs.CastToScriptClass( @pEntity ) );
							CustomKeyvalues@ kvOtherBomb = pEntity.GetCustomKeyvalues();
							if( kvOtherBomb !is null && kvOtherBomb.GetKeyvalue( "$i_exploding" ).GetInteger() == 0 )
							{
								g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_exploding", "1" );
								pBomb.pev.nextthink = g_Engine.time + 0.2;
							}
						}
					}
				}
				else
					break;
			}
			
			for( int i = 1; i < iBombStrength + 1; i++ )
			{
				@pTile = g_EntityFuncs.FindEntityInSphere( null, self.pev.origin + Vector( 0, i * 64, 0 ), 28 , "info_tile" );
				if( pTile !is null )
				{
					if( iY1Block > 0 )
						break;				
					te_explosion( pTile.pev.origin );
					while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pTile.pev.origin + Vector( 0, 0, 36 ), 38 , "*", "classname" ) ) !is null )
					{
						if( pEntity is null )
							continue;
						
						pEntity.TakeDamage( self.pev, self.pev, 50, DMG_BLAST );
						if( pEntity.pev.classname == "func_crate" )
							iY1Block++;		
						
						if( pEntity.pev.classname == "func_bomb" )
						{
							auto pBomb = cast<CFuncBomb@>( g_EntityFuncs.CastToScriptClass( @pEntity ) );
							CustomKeyvalues@ kvOtherBomb = pEntity.GetCustomKeyvalues();
							if( kvOtherBomb !is null && kvOtherBomb.GetKeyvalue( "$i_exploding" ).GetInteger() == 0 )
							{
								g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_exploding", "1" );
								pBomb.pev.nextthink = g_Engine.time + 0.2;
							}
						}
					}
				}		
				else
					break;
			}	
			
			for( int i = 1; i < iBombStrength + 1; i++ )
			{
				@pTile = g_EntityFuncs.FindEntityInSphere( null, self.pev.origin + Vector( 0, i * -64, 0 ), 28 , "info_tile" );
				if( pTile !is null )
				{
					if( iY2Block > 0 )
						break;				
					te_explosion( pTile.pev.origin );
					while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pTile.pev.origin + Vector( 0, 0, 36 ), 38 , "*", "classname" ) ) !is null )
					{
						if( pEntity is null )
							continue;
						
						pEntity.TakeDamage( self.pev, self.pev, 50, DMG_BLAST );
						if( pEntity.pev.classname == "func_crate" )
							iY2Block++;	
						
						if( pEntity.pev.classname == "func_bomb" )
						{
							auto pBomb = cast<CFuncBomb@>( g_EntityFuncs.CastToScriptClass( @pEntity ) );
							CustomKeyvalues@ kvOtherBomb = pEntity.GetCustomKeyvalues();
							if( kvOtherBomb !is null && kvOtherBomb.GetKeyvalue( "$i_exploding" ).GetInteger() == 0 )
							{
								g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_exploding", "1" );
								pBomb.pev.nextthink = g_Engine.time + 0.2;
							}
						}
					}
				}
				else
					break;
			}		

			SetThink( null );	
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( kvBomb.GetKeyvalue( "$i_ownerIndex" ).GetInteger() );
			
			if( pPlayer !is null )
				UnattachBomb( pPlayer );
				
			g_EntityFuncs.Remove( self );		
		}
	}
	
	void te_breakmodel(Vector pos, Vector size, Vector velocity, 
		uint8 speedNoise=16, string model=g_szBombGibModel, 
		uint8 count=4, uint8 life=8, uint8 flags=2,
		NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
	{
		NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
		m.WriteByte(TE_BREAKMODEL);
		m.WriteCoord(pos.x);
		m.WriteCoord(pos.y);
		m.WriteCoord(pos.z);
		m.WriteCoord(size.x);
		m.WriteCoord(size.y);
		m.WriteCoord(size.z);
		m.WriteCoord(velocity.x);
		m.WriteCoord(velocity.y);
		m.WriteCoord(velocity.z);
		m.WriteByte(speedNoise);
		m.WriteShort(g_EngineFuncs.ModelIndex(model));
		m.WriteByte(count);
		m.WriteByte(life);
		m.WriteByte(flags);
		m.End();
	}	
	
	void te_explosion(Vector pos, string sprite=g_szExplosionSprite, 
		int scale=10, int frameRate=15, int flags=4,
		NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
	{
		NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
		m.WriteByte(TE_EXPLOSION);
		m.WriteCoord(pos.x);
		m.WriteCoord(pos.y);
		m.WriteCoord(pos.z);
		m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
		m.WriteByte(scale);
		m.WriteByte(frameRate);
		m.WriteByte(flags);
		m.End();
	}	
}
class CFuncCrate : ScriptBaseEntity
{
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, self.pev.model );
		
		self.pev.solid = SOLID_BSP;
		//Although crates don't move, they need pushstep move type so they are crushable
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		self.pev.nextthink = g_Engine.time + 1;
		
		if( self.pev.health == 0.0f )
			self.pev.health  = g_flCrateHealth;
	}
	
	void Killed( entvars_t@ pevAtttacker, int iGibbed )
	{	
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_STREAM, CrateDeathSoundEvents[Math.RandomLong( 0, 2 )], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		te_breakmodel( self.pev.origin + Vector( 0, 0, 64 ), self.pev.maxs - self.pev.mins, Vector( 0, 0, 50 ) );
		SetThink( null );
		
		g_EntityFuncs.FireTargets( self.pev.target, self, self, USE_TOGGLE );
		
		g_EntityFuncs.Remove( self );
	}

	void Think()
	{
		self.pev.nextthink = g_Engine.time + 1;
		
		CBasePlayer@ pPlayerOverCrate;
		
		@pPlayerOverCrate = cast<CBasePlayer@>( g_EntityFuncs.FindEntityInSphere( null, self.pev.origin + Vector( 0, 0, 72 ), 18 , "player", "classname" ) );
		if( pPlayerOverCrate !is null and pPlayerOverCrate.IsAlive() )
		{
			g_EntityFuncs.FireTargets( "cheater_mm", pPlayerOverCrate, null, USE_ON, 0, 0 );
		}		
	}
	
	void te_breakmodel(Vector pos, Vector size, Vector velocity, 
		uint8 speedNoise=16, string model="models/woodgibs.mdl", 
		uint8 count=4, uint8 life=8, uint8 flags=8,
		NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
	{
		NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
		m.WriteByte(TE_BREAKMODEL);
		m.WriteCoord(pos.x);
		m.WriteCoord(pos.y);
		m.WriteCoord(pos.z);
		m.WriteCoord(size.x);
		m.WriteCoord(size.y);
		m.WriteCoord(size.z);
		m.WriteCoord(velocity.x);
		m.WriteCoord(velocity.y);
		m.WriteCoord(velocity.z);
		m.WriteByte(speedNoise);
		m.WriteShort(g_EngineFuncs.ModelIndex(model));
		m.WriteByte(count);
		m.WriteByte(life);
		m.WriteByte(flags);
		m.End();
	}		
}

class CPowerupBomb : ScriptBaseEntity
{
	private float m_flNextTouchTime;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, self.pev.model );
		
		self.pev.solid = SOLID_BSP;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		
		if( self.pev.health == 0.0f )
			self.pev.health  = g_flCrateHealth;
		
		m_flNextTouchTime = g_Engine.time + 1.0f;
	}
	
	void Touch( CBaseEntity@ pEntity )
	{
		if( m_flNextTouchTime > g_Engine.time )
			return;
		
		if( pEntity !is null )
		{
			if( pEntity.IsPlayer() )
			{
				ClearPoison( pEntity );
				CustomKeyvalues@ kvEntity = pEntity.GetCustomKeyvalues();
				
				m_flNextTouchTime = g_Engine.time + 1.0f;
				
				if( kvEntity is null || !kvEntity.HasKeyvalue( "$i_maxBombCount" ) )
					return;
				
				if ( kvEntity.GetKeyvalue( "$i_maxBombCount" ).GetInteger() < 3 )
				{
					string szMaxBombCount;
					szMaxBombCount = string( kvEntity.GetKeyvalue( "$i_maxBombCount" ).GetInteger() + 1 );
					g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_maxBombCount", szMaxBombCount );
					AttachBombSprite( pEntity );
					self.Killed( null, 0 );
				}
				else
				{
					self.Killed( null, 0 );
				}
			}
		}
	}	
}

class CPowerupLife : ScriptBaseEntity
{
	private float m_flNextTouchTime;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, self.pev.model );
		
		self.pev.solid = SOLID_BSP;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		
		if( self.pev.health == 0.0f )
			self.pev.health  = g_flCrateHealth;
		
		m_flNextTouchTime = g_Engine.time + 1.0f;
	}
	
	void Touch( CBaseEntity@ pEntity )
	{
		if( m_flNextTouchTime > g_Engine.time )
			return;
		
		if( pEntity !is null )
		{
			if( pEntity.IsPlayer() )
			{
				m_flNextTouchTime = g_Engine.time + 3.0f;
				ClearPoison( pEntity );
				if( pEntity.pev.health > ( pEntity.pev.max_health - g_iExplodeDamage ) )
					pEntity.pev.health = pEntity.pev.health + ( pEntity.pev.max_health - pEntity.pev.health );
				else
					pEntity.pev.health = pEntity.pev.health + g_iExplodeDamage;
				
				AttachLifeSprite( pEntity );
				self.Killed( null, 0 );
			}
		}
	}			
}

class CPowerupFire : ScriptBaseEntity
{
	private float m_flNextTouchTime;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, self.pev.model );
		
		self.pev.solid = SOLID_BSP;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		
		if( self.pev.health == 0.0f )
			self.pev.health  = g_flCrateHealth;
		
		m_flNextTouchTime = g_Engine.time + 1.0f;
	}
	
	void Touch( CBaseEntity@ pEntity )
	{
		if( m_flNextTouchTime > g_Engine.time )
			return;
		
		if( pEntity !is null )
		{
			if( pEntity.IsPlayer() )
			{
				ClearPoison( pEntity );
				CustomKeyvalues@ kvEntity = pEntity.GetCustomKeyvalues();
				
				m_flNextTouchTime = g_Engine.time + 1.0f;
				
				if( kvEntity is null || !kvEntity.HasKeyvalue( "$i_ownBombStrength" ) )
					return;
				
				if ( kvEntity.GetKeyvalue( "$i_ownBombStrength" ).GetInteger() < 3 )
				{
					string szPlayerBombStrength = string( kvEntity.GetKeyvalue( "$i_ownBombStrength" ).GetInteger() + 1 );
					g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_ownBombStrength", szPlayerBombStrength );
					self.Killed( null, 0 );
				}
				else
				{
					self.Killed( null, 0 );
				}
			}
		}
	}
}

class CPowerupSkate : ScriptBaseEntity
{
	private float m_flNextTouchTime;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, self.pev.model );
		
		self.pev.solid = SOLID_BSP;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		
		if( self.pev.health == 0.0f )
			self.pev.health  = g_flCrateHealth;
		
		m_flNextTouchTime = g_Engine.time + 1.0f;
	}
	
	void Touch( CBaseEntity@ pEntity )
	{
		if( m_flNextTouchTime > g_Engine.time )
			return;
		
		if( pEntity !is null )
		{
			if( pEntity.IsPlayer() )
			{
				CBasePlayer@ pPlayer = cast<CBasePlayer@>( pEntity );
				ClearPoison( pPlayer );
				m_flNextTouchTime = g_Engine.time + 3.0f;
				int iNewSpeed = pPlayer.GetMaxSpeed() + 20;
				pPlayer.SetMaxSpeed( iNewSpeed );
				self.Killed( null, 0 );
			}
		}
	}			
}

class CPowerupSkull : ScriptBaseEntity
{
	private float m_flNextTouchTime;
	private int m_iPoisonEffect;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, self.pev.model );
		
		self.pev.solid = SOLID_BSP;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		
		if( self.pev.health == 0.0f )
			self.pev.health  = g_flCrateHealth;
		
		m_flNextTouchTime = g_Engine.time + 1.0f;
	}
	
	void Touch( CBaseEntity@ pEntity )
	{
		if( m_flNextTouchTime > g_Engine.time )
			return;
		
		if( pEntity !is null )
		{
			if( pEntity.IsPlayer() )
			{
				CBasePlayer@ pPlayer = cast<CBasePlayer@>( pEntity );
				CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
				m_flNextTouchTime = g_Engine.time + 3.0f;
				ClearPoison( pPlayer );
				m_iPoisonEffect = Math.RandomLong( 0, 4 );
				
				AttachPoisonSprite( pPlayer );
				
				switch( m_iPoisonEffect )
				{
					case 0:
						pPlayer.SetMaxSpeed( 80 );
						g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisoned", "1" );
						g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisonType", string( m_iPoisonEffect ) );
						g_EngineFuncs.ClientPrintf( pPlayer, print_center, "TOO SLOW!\n" );
						break;
						
					case 1:
						pPlayer.SetMaxSpeed( 800 );
						g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisoned", "1" );
						g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisonType", string( m_iPoisonEffect ) );
						g_EngineFuncs.ClientPrintf( pPlayer, print_center, "TOO FAST!\n" );
						break;
						
					case 2:
						g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisoned", "1" );
						g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisonType", string( m_iPoisonEffect ) );
						g_EngineFuncs.ClientPrintf( pPlayer, print_center, "CONSTIPATED!\n" );
						break;
						
					case 3:
						g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisoned", "1" );
						g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisonType", string( m_iPoisonEffect ) );
						g_EngineFuncs.ClientPrintf( pPlayer, print_center, "WEAK BOMBS!\n" );
						break;
						
					case 4:
						CreateScream( pPlayer );
						g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisoned", "1" );
						g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_poisonType", string( m_iPoisonEffect ) );
						g_EngineFuncs.ClientPrintf( pPlayer, print_center, "DIARRHEA!\n" );		
						break;
						
					default:
						break;
				}
				self.Killed( null, 0 );
			}
		}
	}
}