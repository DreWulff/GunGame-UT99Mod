class GGMessage expands LocalMessagePlus;

//
// GG Messages
//
// Switch 0: You have no ammo.
//

var localized string YouHaveNoAmmoString;
var string FeignKey;
var float Offset;

static function float GetOffset(int Switch, float YL, float ClipY )
{
	return ClipY - YL*2 - 0.0833*ClipY;
}

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1, 
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	return Default.YouHaveNoAmmoString;
}

defaultproperties
{
     YouHaveNoAmmoString="You ran out of ammo. Press F to chicken out!"
     YellowColor=(R=255,G=255)
     FontSize=1
     bIsSpecial=True
     bIsConsoleMessage=False
     bFadeMessage=True
     Lifetime=1
     DrawColor=(R=0,G=128)
     YPos=196.000000
     bCenter=True
}
