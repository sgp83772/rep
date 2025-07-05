/*
    Скрипт спавна вертолётов по всей карте
    Особенности:
    - Х повреждённых вертолётов без топлива
    - Равномерное распределение по всей карте
    - Минимум Y м от объектов/воды/камней
    - Только невооружённые модели
*/

// ===== КОНФИГУРАЦИЯ =====
private _helis = [
    "B_Heli_Light_01_F",        // MH-9 Hummingbird
    "B_Heli_Transport_01_F",    // UH-80 Ghost Hawk
    "B_Heli_Transport_03_F",    // CH-67 Huron
    "C_Heli_Light_01_civil_F",  // M-900 (гражданский)
    "I_Heli_light_03_unarmed_F" // WY-55 Hellcat (без вооружения)
];
private _maxHelis = 2;         // <-- МЕНЯЙТЕ ЭТО ЧИСЛО ДЛЯ РЕГУЛИРОВКИ
private _minDistFromObjects = 50; // Минимум 50м от объектов
private _maxAttempts = 50;      // Макс. попыток найти позицию для каждого вертолёта

// ===== ОЧИСТКА СТАРЫХ ВЕРТОЛЁТОВ =====
{ deleteVehicle _x } forEach (allMissionObjects "Helicopter");

// ===== ФУНКЦИЯ ПОИСКА ПОДХОДЯЩЕЙ ПОЗИЦИИ =====
private _fnc_findValidPosition = {
    params ["_minDist"];
    private _pos = [];
    private _attempts = 0;
    
    while {_pos isEqualTo [] && _attempts < _maxAttempts} do {
        // Генерируем случайные координаты по всей карте
        private _testPos = [
            random worldSize,  // X
            random worldSize,  // Y
            0                  // Z
        ];
        
        // Проверяем условия
        private _isValid = true;
        _isValid = _isValid && {!(surfaceIsWater _testPos)};               // Не в воде
        _isValid = _isValid && {!(isOnRoad _testPos)};                     // Не на дороге
        _isValid = _isValid && {(nearestTerrainObjects [_testPos, ["HOUSE", "TREE", "SMALL TREE", "ROCK", "ROCKS"], _minDist]) isEqualTo []}; // Вдали от объектов
        
        if (_isValid) then { _pos = _testPos };
        _attempts = _attempts + 1;
    };
    
    _pos
};

// ===== ОСНОВНОЙ ЦИКЛ СПАВНА =====
private _spawnedHelis = [];
private _successCount = 0;

for "_i" from 1 to _maxHelis do {
    // Ищем валидную позицию
    private _pos = [_minDistFromObjects] call _fnc_findValidPosition;
    
    if (_pos isEqualTo []) then {
        diag_log format [">> Не найдена позиция для вертолёта %1", _i];
        continue;
    };
    
    // Создаём вертолёт
    private _heli = createVehicle [selectRandom _helis, _pos, [], 0, "NONE"];
    _heli setDir random 360;
    
    // Настраиваем состояние
    _heli setFuel 0.1;             // Уровень топлива
    _heli setDamage 0.7;         // Повреждённый
    _heli setVehicleAmmo 0;      // Без боеприпасов
    _heli enableSimulationGlobal false; // Оптимизация
    
    // Лёгкое смещение для естественности
    _heli setPos (_heli modelToWorld [random 3 - 1.5, random 3 - 1.5, 0]);
    
    _spawnedHelis pushBack _heli;
    _successCount = _successCount + 1;
    
    if (_i % 10 == 0) then { sleep 0.1 }; // Задержка для стабильности
};

// ===== ИТОГИ =====
diag_log format [">> Успешно заспавнено %1/%2 вертолётов", _successCount, _maxHelis];
[format ["Создано вертолётов: %1", _successCount], "systemChat"] remoteExec ["call", 0];
