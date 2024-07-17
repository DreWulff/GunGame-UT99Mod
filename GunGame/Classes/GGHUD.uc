//=============================================================================
// GunGameHUD
//=============================================================================
class GGHUD extends ChallengeHUD;

var string KeyAlias[255];
var string FeignKey;

function Timer()
{
	Super.Timer();

	if ( (PlayerOwner == None) || (PawnOwner == None) )
		return;
	if ( PawnOwner.Weapon.Ammotype.AmmoAmount == 0 && !PawnOwner.Weapon.IsA('Translocator'))
		PlayerOwner.ReceiveLocalizedMessage( class'GunGame.GGMessage');
}

simulated function PostBeginPlay ()
{
	FindFeignDeathKey(PawnOwner);
	Super.PostBeginPlay();
}

function FindFeignDeathKey(Pawn P)
{
	local int i;

	if (P.IsA('PlayerPawn'))
	{
		LoadKeyBindings(PlayerPawn(P));
		for (i=0; i<255; i++)
		{
			if (KeyAlias[i] ~= "FeignDeath")
			{
				if (FeignKey != "")
					FeignKey = FeignKey$","@class'UMenuCustomizeClientWindow'.default.LocalizedKeyName[i];
				else
					FeignKey = class'UMenuCustomizeClientWindow'.default.LocalizedKeyName[i];
			}
		}
	}
	
}

function LoadKeyBindings(PlayerPawn P)
{
	local int i;
	local string k;

	for (i=0; i<255; i++)
	{
		k = P.ConsoleCommand( "KEYNAME "$i );
		KeyAlias[i] = P.ConsoleCommand( "KEYBINDING "$k );
	}
}