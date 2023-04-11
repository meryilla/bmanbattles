class CPowerupBomb : ScriptBaseAnimating
{
	private float m_flNextTouchTime;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, g_szPowerupModel );
		self.SetBodygroup( 0, 2 );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetSize( self.pev, Vector( -18, -18, 0 ), Vector( 18, 18, 50 ) );
		
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		
		//when classic cam is enabled set the animation so that the powerup is visible from above
		if( blClassicCamEnabled )
		{
			self.pev.angles = Vector( 0, 90, 0 );
			self.pev.sequence = 1;
		}
		else
			self.pev.sequence = 0;
		self.pev.frame = 0;
		self.ResetSequenceInfo();	
		
		self.pev.targetname = "powerup_bomb_powerup";
		
		if( self.pev.health == 0.0f )
			self.pev.health  = g_iExplodeDamage;
		
		self.pev.nextthink = g_Engine.time + 0.1f;
	}
	
	void Think()
	{
		CBaseEntity@ pEntity;
		
		while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "player" ) ) !is null )
		{
			if( self.Intersects( pEntity ) )
				break;
			else
				continue;
		}
		
		if( pEntity !is null )
		{
			ClearPoison( pEntity );
			CustomKeyvalues@ kvEntity = pEntity.GetCustomKeyvalues();
			
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
			g_SoundSystem.PlaySound( pEntity.edict(), CHAN_VOICE, "bman/item_get.mp3", 10.0f, 10.0f, 0, PITCH_NORM, pEntity.entindex(), true, pEntity.GetOrigin() );
		}
		self.pev.nextthink = g_Engine.time + 0.1f;
	}	
}

class CPowerupLife : ScriptBaseAnimating
{
	private float m_flNextTouchTime;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, g_szPowerupModel );
		self.SetBodygroup( 0, 7 );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetSize( self.pev, Vector( -18, -18, 0 ), Vector( 18, 18, 50 ) );
		
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		
		//when classic cam is enabled set the animation so that the powerup is visible from above
		if( blClassicCamEnabled )
		{
			self.pev.angles = Vector( 0, 90, 0 );
			self.pev.sequence = 1;
		}
		else
			self.pev.sequence = 0;
		self.pev.frame = 0;
		self.ResetSequenceInfo();		
		
		self.pev.targetname = "powerup_life_powerup";
		
		if( self.pev.health == 0.0f )
			self.pev.health  = g_iExplodeDamage;
		
		self.pev.nextthink = g_Engine.time + 0.1f;
	}
	
	void Think()
	{
		CBaseEntity@ pEntity;
		
		while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "player" ) ) !is null )
		{
			if( self.Intersects( pEntity ) )
				break;
			else
				continue;
		}
		
		if( pEntity !is null )
		{
			if( pEntity.IsPlayer() )
			{
				ClearPoison( pEntity );
				if( pEntity.pev.health > ( pEntity.pev.max_health - g_iExplodeDamage ) )
					pEntity.pev.health = pEntity.pev.health + ( pEntity.pev.max_health - pEntity.pev.health );
				else
					pEntity.pev.health = pEntity.pev.health + g_iExplodeDamage;
				
				AttachLifeSprite( pEntity );
				self.Killed( null, 0 );
			}
			g_SoundSystem.PlaySound( pEntity.edict(), CHAN_VOICE, "bman/item_get.mp3", 10.0f, 10.0f, 0, PITCH_NORM, pEntity.entindex(), true, pEntity.GetOrigin() );
		}
		self.pev.nextthink = g_Engine.time + 0.1f;
	}			
}

class CPowerupFire : ScriptBaseAnimating
{
	private float m_flNextTouchTime;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, g_szPowerupModel );
		self.SetBodygroup( 0, 5 );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetSize( self.pev, Vector( -18, -18, 0 ), Vector( 18, 18, 50 ) );
		
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		
		//when classic cam is enabled set the animation so that the powerup is visible from above
		if( blClassicCamEnabled )
		{
			self.pev.angles = Vector( 0, 90, 0 );
			self.pev.sequence = 1;
		}
		else
			self.pev.sequence = 0;
		self.pev.frame = 0;
		self.ResetSequenceInfo();	
		
		self.pev.targetname = "powerup_fire_powerup";
		
		if( self.pev.health == 0.0f )
			self.pev.health  = g_iExplodeDamage;
		
		self.pev.nextthink = g_Engine.time + 0.1f;
	}
	
	void Think()
	{
		CBaseEntity@ pEntity;
		
		while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "player" ) ) !is null )
		{
			if( self.Intersects( pEntity ) )
				break;
			else
				continue;
		}
		
		if( pEntity !is null )
		{
			if( pEntity.IsPlayer() )
			{
				ClearPoison( pEntity );
				CustomKeyvalues@ kvEntity = pEntity.GetCustomKeyvalues();
				
				
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
				g_SoundSystem.PlaySound( pEntity.edict(), CHAN_VOICE, "bman/item_get.mp3", 10.0f, 10.0f, 0, PITCH_NORM, pEntity.entindex(), true, pEntity.GetOrigin() );
			}
		}
		self.pev.nextthink = g_Engine.time + 0.1f;
	}
}

class CPowerupSkate : ScriptBaseAnimating
{
	private float m_flNextTouchTime;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, g_szPowerupModel );
		self.SetBodygroup( 0, 15 );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetSize( self.pev, Vector( -18, -18, 0 ), Vector( 18, 18, 50 ) );
		
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		
		//when classic cam is enabled set the animation so that the powerup is visible from above
		if( blClassicCamEnabled )
		{
			self.pev.angles = Vector( 0, 90, 0 );
			self.pev.sequence = 1;
		}
		else
			self.pev.sequence = 0;
		self.pev.frame = 0;
		self.ResetSequenceInfo();	
		
		self.pev.targetname = "powerup_skate_powerup";
		
		if( self.pev.health == 0.0f )
			self.pev.health  = g_iExplodeDamage;
		
		self.pev.nextthink = g_Engine.time + 0.1f;
	}
	
	void Think()
	{
		CBaseEntity@ pEntity;
		
		while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "player" ) ) !is null )
		{
			if( self.Intersects( pEntity ) )
				break;
			else
				continue;
		}
		
		if( pEntity !is null )
		{
			if( pEntity.IsPlayer() )
			{
				CBasePlayer@ pPlayer = cast<CBasePlayer@>( pEntity );
				ClearPoison( pPlayer );
				int iNewSpeed = pPlayer.GetMaxSpeed() + 20;
				pPlayer.SetMaxSpeed( iNewSpeed );
				self.Killed( null, 0 );
			}
			g_SoundSystem.PlaySound( pEntity.edict(), CHAN_VOICE, "bman/item_get.mp3", 10.0f, 10.0f, 0, PITCH_NORM, pEntity.entindex(), true, pEntity.GetOrigin() );
		}
		self.pev.nextthink = g_Engine.time + 0.1f;
	}			
}

class CPowerupSkull : ScriptBaseAnimating
{
	private float m_flNextTouchTime;
	private int m_iPoisonEffect;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, g_szPowerupModel );
		self.SetBodygroup( 0, 13 );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetSize( self.pev, Vector( -18, -18, 0 ), Vector( 18, 18, 50 ) );
		
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		
		//when classic cam is enabled set the animation so that the powerup is visible from above
		if( blClassicCamEnabled )
		{
			self.pev.angles = Vector( 0, 90, 0 );
			self.pev.sequence = 1;
		}
		else
			self.pev.sequence = 0;
		self.pev.frame = 0;
		self.ResetSequenceInfo();	
		
		self.pev.targetname = "powerup_skull_powerup";
		
		if( self.pev.health == 0.0f )
			self.pev.health  = g_iExplodeDamage;
		
		self.pev.nextthink = g_Engine.time + 0.1f;
	}
	
	void Think()
	{
		CBaseEntity@ pEntity;
		
		while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "player" ) ) !is null )
		{
			if( self.Intersects( pEntity ) )
				break;
			else
				continue;
		}
		
		if( pEntity !is null )
		{
			if( pEntity.IsPlayer() )
			{
				CBasePlayer@ pPlayer = cast<CBasePlayer@>( pEntity );
				CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
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
				g_SoundSystem.PlaySound( pEntity.edict(), CHAN_VOICE, "bman/skull.mp3", 10.0f, 10.0f, 0, PITCH_NORM, pEntity.entindex(), true, pEntity.GetOrigin() );
			}
		}
		self.pev.nextthink = g_Engine.time + 0.1f;
	}
}

class CPowerupKick : ScriptBaseAnimating
{
	private float m_flNextTouchTime;
	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, g_szPowerupModel );
		self.SetBodygroup( 0, 8 );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetSize( self.pev, Vector( -18, -18, 0 ), Vector( 18, 18, 50 ) );
		
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_PUSHSTEP;
		self.pev.takedamage = DAMAGE_YES;
		
		//when classic cam is enabled set the animation so that the powerup is visible from above
		if( blClassicCamEnabled )
		{
			self.pev.angles = Vector( 0, 90, 0 );
			self.pev.sequence = 1;
		}
		else
			self.pev.sequence = 0;
		self.pev.frame = 0;
		self.ResetSequenceInfo();	
		
		self.pev.targetname = "powerup_kick_powerup";
		
		if( self.pev.health == 0.0f )
			self.pev.health = g_iExplodeDamage;
		
		self.pev.nextthink = g_Engine.time + 0.1f;
	}
	
	void Think()
	{
		CBaseEntity@ pEntity;
		
		while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "player" ) ) !is null )
		{
			if( self.Intersects( pEntity ) )
				break;
			else
				continue;
		}
		
		if( pEntity !is null )
		{
			if( pEntity.IsPlayer() )
			{
				CBasePlayer@ pPlayer = cast<CBasePlayer@>( pEntity );
				ClearPoison( pPlayer );
				g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_canKick", "1" );
				self.Killed( null, 0 );
			}
			g_SoundSystem.PlaySound( pEntity.edict(), CHAN_VOICE, "bman/item_get.mp3", 10.0f, 10.0f, 0, PITCH_NORM, pEntity.entindex(), true, pEntity.GetOrigin() );
		}
		self.pev.nextthink = g_Engine.time + 0.1f;
	}			
}