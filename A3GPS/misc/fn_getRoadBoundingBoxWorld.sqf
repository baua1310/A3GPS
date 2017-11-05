#include "..\macros.h"
/**
	@Author : [Utopia] Amaury
	@Creation : ??/10/17
	@Modified : --
	@Description : get the road bounding box in position world
		Return : Array 
**/

params [
	["_road",objNull,[objNull]],
	["_lenghtMultiplicator",1,[0]],
	["_widthMultiplicator",1,[0]]
];

private _bb = boundingBox _road;
private _direction = [_road] call misc_fnc_getRoadDir;

_fullbb = [
	_bb select 0,
	[
		(_bb select 1 select 0),
		(_bb select 0 select 1),
		(_bb select 1 select 2)
	],
	_bb select 1,
	[
		(_bb select 0 select 0),
		(_bb select 1 select 1),
		(_bb select 0 select 2)
	]
];

_bbw = _fullbb apply {
	_x set [0,(_x select 0) * _lenghtMultiplicator];
	_x set [1,(_x select 1) * _widthMultiplicator];
	_road modelToWorld ([_x,-_direction] call BIS_fnc_rotateVector2D)
};

_bbw


// {[nil,_x] call misc_fnc_createMarker}foreach ([roadAt player] call misc_fnc_getRoadBoundingBoxWorld);