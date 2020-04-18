local options = {}
local isDebug = false

function options.SetDifficulty()
    if isDebug then 
        EnemyLimit = 100
        TimeDifficulty = 5000
        TimeIncrease = 1000
        EnemiesPerWave = 15
        MinTimeBetweenWaves = 1000
        MaxTimeBetweenWaves = 4000
        EggCapacity = 1000
        EgginInv = 1000
        MaxHearts = 5
        HeartDropChance = 1
        HeartLifeTime = 10
        MaxEggsPerEnemy = 5
        MinPlayerAccuracy = 0.2
        RedChance = 4
        BlueChance = 3
        BlackChance = 2
        InitialCoopHealth = 1000
        DifficultyScore = 1
    elseif(Difficulty == "Easy") then
        EnemyLimit = 30
        TimeDifficulty = 120000
        TimeIncrease = 30000
        EnemiesPerWave = 4
        MinTimeBetweenWaves = 5000
        MaxTimeBetweenWaves = 10000
        EggCapacity = 30
        EgginInv = 15
        MaxHearts = 6
        HeartDropChance = 25
        HeartLifeTime = 5
        MaxEggsPerEnemy = 2
        MinPlayerAccuracy = 0.5
        RedChance = 9
        BlueChance = 19
        BlackChance = 10
        InitialCoopHealth = 1500
        DifficultyScore = 0.5
    elseif(Difficulty == "Normal") then
        EnemyLimit = 50
        TimeDifficulty = 120000
        TimeIncrease = 30000
        EnemiesPerWave = 5
        MinTimeBetweenWaves = 5000
        MaxTimeBetweenWaves = 10000
        EggCapacity = 20
        EgginInv = 10
        MaxHearts = 5
        HeartDropChance = 30
        HeartLifeTime = 4
        MaxEggsPerEnemy = 2
        MinPlayerAccuracy = 0.7
        RedChance = 9
        BlueChance = 19
        BlackChance = 10
        InitialCoopHealth = 1000
        DifficultyScore = 1
    elseif Difficulty == "Hard" then
        EnemyLimit = 60
        TimeDifficulty = 120000
        TimeIncrease = 30000
        EnemiesPerWave = 6
        MinTimeBetweenWaves = 5000
        MaxTimeBetweenWaves = 10000
        EggCapacity = 10
        EgginInv = 5
        MaxHearts = 4
        HeartDropChance = 30
        HeartLifeTime = 3
        MaxEggsPerEnemy = 2
        MinPlayerAccuracy = 0.85
        RedChance = 9
        BlueChance = 19
        BlackChance = 10
        InitialCoopHealth = 750
        DifficultyScore = 1.5
    end
end

return options