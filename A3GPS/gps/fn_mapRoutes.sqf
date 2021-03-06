#include "..\macros.h"
/**
  @Author : [Utopia] Amaury
  @Creation : 1/02/17
  @Modified : 22/10/17
  @Description :trying to make a virtual map because arma road system ...
  				this file has changed so much ...
**/
scriptName "gps_virtual_mapping";

_start = diag_tickTime;
[format [["STR_LOG_VMAP_INIT_START"] call misc_fnc_localize]] call gps_fnc_log;

gps_data_map_center = [worldSize / 2,worldSize / 2,0];

[] call gps_fnc_loadWorldData;

["getting roads"] call gps_fnc_log;

gps_allRoads = [] call gps_fnc_getAllRoads;

["done"] call gps_fnc_log;

_max_road_index = (gps_allRoads apply {parseNumber str _x});
gps_max_road_index = selectMax _max_road_index;

private _gps_allRoadsWithInter = [];
private _gps_allCrossRoads = [];
gps_allCrossRoadsWithWeight = [gps_max_road_index] call misc_fnc_hashTable_create;
gps_onlyCrossRoads = [];
gps_roadSegments = [gps_max_road_index] call misc_fnc_hashTable_create;
gps_roadsWithConnected =  [gps_max_road_index] call misc_fnc_hashTable_create;

["mapping road intersect"] call gps_fnc_log;

_gps_allRoadsWithInter = gps_allRoads apply { //FINALLY FIXED THIS 
  private _road = _x;
  private _near = getPosATL _road nearRoads 15;
  private _connected = roadsConnectedTo _road;

  _near = (_near - _connected) - [_road];

  _BB_road = [_road,nil,0.25] call misc_fnc_getRoadBoundingBoxWorld;

  {
    _BB_x = [_x,nil,0.25] call misc_fnc_getRoadBoundingBoxWorld;
     if(count (roadsConnectedTo _x) == 1 
        || [_BB_road,_BB_x] call misc_fnc_arePolygonsOverlapping
      ) then {
        _connected pushBack _x;
        if([gps_roadsWithConnected,parseNumber str _x] call misc_fnc_hashTable_exists) then {
          private _connected = [gps_roadsWithConnected,parseNumber str _x] call misc_fnc_hashTable_find;
          _connected pushBack _road;
        }else{
          [gps_roadsWithConnected,parseNumber str _x,[_road]] call misc_fnc_hashTable_set;
        };
     };
  }foreach _near;

  _currentConnected = [gps_roadsWithConnected,parseNumber str _road] call misc_fnc_hashTable_find;
  if(isNil "_currentConnected") then {
      [gps_roadsWithConnected,parseNumber str _road,_connected] call misc_fnc_hashTable_set;
  }else{
      _currentConnected append _connected;
  };

  [_road,_connected]
};

["done"] call gps_fnc_log;

{
  _connected = [gps_roadsWithConnected,parseNumber str (_x select 0)] call misc_fnc_hashTable_find;
  if(count _connected > 2) then {_gps_allCrossRoads pushBack _x};
} forEach _gps_allRoadsWithInter;

gps_onlyCrossRoads = _gps_allCrossRoads apply {_x select 0};

private _gps_mapping_threads = [];
private _max_running_threads = 40;

{
  _gps_mapping_threads pushBack (_x spawn gps_fnc_mapNodeValues);
  if(count _gps_mapping_threads >= _max_running_threads) then {
     waitUntil {
       _gps_mapping_threads = _gps_mapping_threads - [scriptNull];
       count _gps_mapping_threads < _max_running_threads
     };
  };
}foreach _gps_allCrossRoads;

waitUntil {
  ({!scriptDone _x} count _gps_mapping_threads) == 0
};

[format["Loaded : %1 roads|%2 crossroads|%3 road segments",count gps_allRoads,count gps_onlyCrossRoads,count gps_roadSegments]] call gps_fnc_log;

[format [["STR_LOG_VMAP_INIT_DONE"] call misc_fnc_localize,round (diag_tickTime - _start)]] call gps_fnc_log;