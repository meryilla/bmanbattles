class CFuncBomb : ScriptBaseEntity
{
	private float m_flExplodeTime;
	private array<int> m_iPlayersOnBombTile;
	private bool m_blOwnerInTile = true;
	private bool m_blIsMoving = false;
	private float m_fLastKickTime = g_Engine.time;
	
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
		self.pev.nextthink = g_Engine.time + 0.01;
		
		CBasePlayer@ pPlayerInBomb;
		CBaseEntity@ pTile;
		CBaseEntity@ pEntity;
		CustomKeyvalues@ kvBomb = self.GetCustomKeyvalues();
		
		//For traces
		Vector vecStart, vecEnd;
		
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
		
		if( m_blIsMoving && self.pev.velocity == Vector( 0, 0, 0 ) )
			m_blIsMoving = false;
			
		if( m_blIsMoving )
		{
			@pTile = g_EntityFuncs.FindEntityInSphere( null, self.pev.origin, 1 , "info_tile" );
			if( pTile !is null )
			{
				TraceResult trTileClear;
				vecStart = pTile.pev.origin + Vector( 0, 0, 16 );
				
				if( self.pev.velocity.x > 0 )
					vecEnd = self.pev.origin + Vector( 64, 0, 0 );
				else if( self.pev.velocity.x < 0 )
					vecEnd = self.pev.origin + Vector( -64, 0, 0 );
				else if( self.pev.velocity.y > 0 )
					vecEnd = self.pev.origin + Vector( 0, 64, 0 );
				else if( self.pev.velocity.y < 0 )
					vecEnd = self.pev.origin + Vector( 0, -64, 0 );
				
				g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, self.edict(), trTileClear );
				
				if( trTileClear.flFraction < 1 )
				{
					self.pev.velocity = Vector( 0, 0, 0 );
					m_blIsMoving = false;
					return;
				}
			
			}
		}
		
		if( self.pev.solid == SOLID_BBOX && !m_blIsMoving && m_fLastKickTime < g_Engine.time )
		{
			CBaseEntity@ pEntityContact;
		
			while( ( @pEntityContact = g_EntityFuncs.FindEntityByClassname( pEntityContact, "player" ) ) !is null )
			{
				if( self.Intersects( pEntityContact ) )
					break;
				else
					continue;
			}
			
			if( pEntityContact !is null && pEntityContact.IsPlayer() )
			{
				CustomKeyvalues@ kvEntityContact = pEntityContact.GetCustomKeyvalues();
				
				if( kvEntityContact.GetKeyvalue( "$i_canKick" ).GetInteger() == 1  )
				{
					float flXDiff = abs( self.pev.origin.x - pEntityContact.pev.origin.x );
					float flYDiff = abs( self.pev.origin.y - pEntityContact.pev.origin.y );
					
					if( self.pev.origin.x > pEntityContact.pev.origin.x && flXDiff >= 32 && IsNextTileClear( self.pev.origin + Vector( 64, 0, 0 ) ) )
					{
						self.pev.velocity.x = 400;
						m_blIsMoving = true;
						m_fLastKickTime = g_Engine.time + 0.5f;
						g_SoundSystem.EmitSoundDyn( pEntityContact.edict(), CHAN_AUTO, "bman/kick.mp3", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );						
					}
					else if( self.pev.origin.x < pEntityContact.pev.origin.x && flXDiff >= 32 && IsNextTileClear( self.pev.origin + Vector( -64, 0, 0 ) ) )
					{
						self.pev.velocity.x = -400;
						m_blIsMoving = true;
						m_fLastKickTime = g_Engine.time + 0.5f;
						g_SoundSystem.EmitSoundDyn( pEntityContact.edict(), CHAN_AUTO, "bman/kick.mp3", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );						
					}
					else if( self.pev.origin.y > pEntityContact.pev.origin.y && flYDiff >= 32 && IsNextTileClear( self.pev.origin + Vector( 0, 64, 0 ) ) )
					{
						self.pev.velocity.y = 400;
						m_blIsMoving = true;
						m_fLastKickTime = g_Engine.time + 0.5f;
						g_SoundSystem.EmitSoundDyn( pEntityContact.edict(), CHAN_AUTO, "bman/kick.mp3", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );						
					}
					else if( self.pev.origin.y < pEntityContact.pev.origin.y && flYDiff >= 32 && IsNextTileClear( self.pev.origin + Vector( 0, -64, 0 ) ) )
					{
						self.pev.velocity.y = -400;
						m_blIsMoving = true;
						m_fLastKickTime = g_Engine.time + 0.5f;
						g_SoundSystem.EmitSoundDyn( pEntityContact.edict(), CHAN_AUTO, "bman/kick.mp3", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
					}
				}
			}
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
				@pTile = g_EntityFuncs.FindEntityInSphere( null, self.pev.origin + Vector( i * 64, 0, 0 ), 28 , "info_tile" );
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
	
	bool IsNextTileClear( Vector vecEnd )
	{
		//Raise it slightly so we don't trace within the floor
		Vector vecStart = self.pev.origin + Vector( 0, 0, 1 );
		
		TraceResult trNextTile;
		g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, self.edict(), trNextTile );	

		if( trNextTile.flFraction < 1 )
			return false;
		else
			return true;
	
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
