//=============================================================================
// GunGame.
//=============================================================================
class GunGame extends DeathMatchPlus;

var config bool bHighDetailGhosts;
var() int Guns;
var int TotalKills, NumGhosts;
var localized string AltStartupMessage;
var PlayerPawn LocalPlayer;

enum GGWeapons
{
	Enforcer,
	Bio,
	Shock,
	Pulse,
	Ripper,
	Minigun,
	Flak,
	Rocket,
	Sniper,
	Translocator
};

event InitGame( string Options, out string Error )
{
	local string InOpt;

	Super.InitGame(Options, Error);
	if ( FragLimit == 0 )
		Guns = 10;
	else
		Guns = Fraglimit;
}

function float GameThreatAdd(Bot aBot, Pawn Other)
{
	if ( !Other.bIsPlayer ) 
		return 0;
	else
		return 0.1 * Other.PlayerReplicationInfo.Score;
}

event playerpawn Login
(
	string Portal,
	string Options,
	out string Error,
	class<playerpawn> SpawnClass
)
{
	local playerpawn NewPlayer;
	local Pawn P;

	// if more than 15% of the game is over, must join as spectator
	if ( TotalKills > 0.15 * (NumPlayers + NumBots) * Guns )
	{
		bDisallowOverride = true;
		SpawnClass = class'CHSpectator';
		if ( (NumSpectators >= MaxSpectators)
			&& ((Level.NetMode != NM_ListenServer) || (NumPlayers > 0)) )
		{
			MaxSpectators++;
		}
	}
	NewPlayer = Super.Login(Portal, Options, Error, SpawnClass);

	if ( (NewPlayer != None) && !NewPlayer.IsA('Spectator') && !NewPlayer.IsA('Commander') )
		NewPlayer.PlayerReplicationInfo.Score = 0;

	return NewPlayer;
}

event PostLogin( playerpawn NewPlayer )
{
	if( NewPlayer.Player != None && Viewport(NewPlayer.Player) != None)
		LocalPlayer = NewPlayer;

	if ( (TotalKills > 0.15 * (NumPlayers + NumBots) * Guns) && NewPlayer.IsA('CHSpectator') )
		GameName = AltStartupMessage;	
	Super.PostLogin(NewPlayer);
	GameName = Default.GameName;
}

function Timer()
{
	local Pawn P;

	Super.Timer();
	For ( P=Level.PawnList; P!=None; P=P.NextPawn )
		if ( P.IsInState('FeigningDeath') )
			P.GibbedBy(P);
		else if ( (P.IsA('Bot')) && (P.Weapon.Ammotype.AmmoAmount == 0) && (!P.Weapon.IsA('Translocator')) )
			P.GibbedBy(P);
}
 
function bool NeedPlayers()
{
	if ( bGameEnded || (TotalKills > 0.15 * (NumPlayers + NumBots) * Guns) )
		return false;
	return (NumPlayers + NumBots < MinPlayers);
}

function bool IsRelevant(actor Other) 
{
	local Mutator M;
	local bool bArenaMutator;

	for (M = BaseMutator; M != None; M = M.NextMutator)
	{
		if (M.IsA('Arena'))
			bArenaMutator = True;
	}

	if ( Other.IsA('Inventory')	&& (Inventory(Other).MyMarker != None) && (Other.IsA('Weapon') || Other.IsA('Ammo')))
	{
		Inventory(Other).MyMarker.markedItem = None;
		return false;
	}

	return Super.IsRelevant(Other);
}

function bool RestartPlayer( pawn aPlayer )	
{
	local NavigationPoint startSpot;
	local bool foundStart;
	local Pawn P;

	if( bRestartLevel && Level.NetMode!=NM_DedicatedServer && Level.NetMode!=NM_ListenServer )
		return true;

	startSpot = FindPlayerStart(None, 255);
	if( startSpot == None )
		return false;
		
	foundStart = aPlayer.SetLocation(startSpot.Location);
	if( foundStart )
	{
		startSpot.PlayTeleportEffect(aPlayer, true);
		aPlayer.SetRotation(startSpot.Rotation);
		aPlayer.ViewRotation = aPlayer.Rotation;
		aPlayer.Acceleration = vect(0,0,0);
		aPlayer.Velocity = vect(0,0,0);
		aPlayer.Health = aPlayer.Default.Health;
		aPlayer.ClientSetRotation( startSpot.Rotation );
		aPlayer.bHidden = false;
		aPlayer.SoundDampening = aPlayer.Default.SoundDampening;
		aPlayer.SetCollision( true, true, true );
		AddDefaultInventory(aPlayer);
	}
	return foundStart;
}

function Logout( pawn Exiting )
{
	Super.Logout(Exiting);
}

function Killed( pawn killer, pawn Other, name damageType )
{
	local int OldFragLimit;

	OldFragLimit = FragLimit;
	FragLimit = 0;

	if ( Other.bIsPlayer )
		TotalKills++;
			
	Super.Killed(Killer, Other, damageType);
	FragLimit = OldFragLimit;
}

function CheckEndGame(Pawn Killer)
{
	local Pawn PawnLink;
	local int StillPlaying;
	local bool bStillHuman;
	local bot B, D;

	if ( bGameEnded )
		return;

	// End the game if there is only one man standing.
	if ( Killer.PlayerReplicationInfo.Score >= Guns )
		EndGame("gungame");
	else { return; }	
}

//
// Discard a player's inventory after he dies.
//
function DiscardInventory( Pawn Other )
{
	local actor dropped;
	local inventory Inv;
	local weapon weap;
	local float speed;

	if( Other.DropWhenKilled != None )
	{
		dropped = Spawn(Other.DropWhenKilled,,,Other.Location);
		Inv = Inventory(dropped);
		if ( Inv != None )
		{ 
			Inv.RespawnTime = 0.0; //don't respawn
			Inv.BecomePickup();		
		}
		if ( dropped != None )
		{
			dropped.RemoteRole = ROLE_DumbProxy;
			dropped.SetPhysics(PHYS_Falling);
			dropped.bCollideWorld = true;
			dropped.Velocity = Other.Velocity + VRand() * 280;
		}
		if ( Inv != None )
			Inv.GotoState('PickUp', 'Dropped');
	}
	Other.Weapon = None;
	Other.SelectedItem = None;	
	for( Inv=Other.Inventory; Inv!=None; Inv=Inv.Inventory )
		Inv.Destroy();
}

//
// Destroy all weapons that Pawn is holding
//
function DiscardWeapons( Pawn Other )
{
	local inventory Inv;
	
	for( Inv=Other.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		if (Inv.IsA('Weapon'))
		{
			Inv.Destroy();
		}
	}
}

function ScoreKill(pawn Killer, pawn Other)
{
	Other.DieCount++;
	if ((Killer != Other) && (Killer != None) && (Killer.PlayerReplicationInfo.Score < Guns))
		Killer.PlayerReplicationInfo.Score += 1;
		Killer.killCount++;
		CheckEndGame(killer);
		DiscardWeapons(Killer);
		GiveWeapon(Killer, GetWeapon(Killer));
	BaseMutator.ScoreKill(Killer, Other);
}

/*
AssessBotAttitude returns a value that translates to an attitude
		0 = ATTITUDE_Fear;
		1 = return ATTITUDE_Hate;
		2 = return ATTITUDE_Ignore;
		3 = return ATTITUDE_Friendly;
*/	
function byte AssessBotAttitude(Bot aBot, Pawn Other)
{
	local float Adjust;

	if ( aBot.bNovice )
		Adjust = -0.2;
	else
		Adjust = -0.2 - 0.1 * aBot.Skill;
	if ( aBot.bKamikaze )
		return 1;
	else if ( Other.IsA('TeamCannon')
		|| (aBot.RelativeStrength(Other) > aBot.Aggressiveness - Adjust) )
		return 0;
	else
		return 1;
}

function AddDefaultInventory( pawn PlayerPawn )
{
	local Weapon NewWeapon;
	local Bot B;

	if ( PlayerPawn.IsA('Spectator') || (bRequireReady && (CountDown > 0)) )
		return;

	// Give weapon at spawn in function of player score
	GiveWeapon(PlayerPawn, GetWeapon(PlayerPawn));
}

function string GetWeapon(Pawn pawn)
{
	switch (pawn.PlayerReplicationInfo.Score % 10)
	{
		case 0:
			return("Botpack.Enforcer");
		case 1:
			return("Botpack.UT_BioRifle");
		case 2:
			return("Botpack.ShockRifle");
		case 3:
			return("Botpack.PulseGun");
		case 4:
			return("Botpack.Ripper");
		case 5:
			return("Botpack.Minigun2");
		case 6:
			return("Botpack.UT_FlakCannon");
		case 7:
			return("Botpack.UT_Eightball");
		case 8:
			return("Botpack.SniperRifle");
		case 9:
			return("Botpack.Translocator");
		default:
			return("Botpack.Enforcer");
	}
}

function ModifyBehaviour(Bot NewBot)
{
	// Set the Bot's Score
	NewBot.PlayerReplicationInfo.Score = 0;

	NewBot.CampingRate += FRand();
}

defaultproperties
{
     bAlwaysForceRespawn=True
     ScoreBoardType=Class'Botpack.TournamentScoreboard'
	 HUDType=Class'GunGame.GGHUD'
     RulesMenuType="UTMenu.UTLMSRulesSC"
     BeaconName="GG"
     GameName="Gun Game"
     StartMessage="Gun'em down!."
     GameEndedMessage="guned the most gamers."
     SingleWaitingMessage="Get ready to run n' gun."
}
