import Darwin
import Foundation

let log = false

enum Resource: CaseIterable {
    case ore
    case clay
    case obsidian
    case geode
    
    var neededResources: [Resource] {
        switch self {
        case .ore:
            return [.ore]
        case .clay:
            return [.ore]
        case .obsidian:
            return [.ore, .clay]
        case .geode:
            return [.ore, .obsidian]
        }
    }
}

enum Action {
    case build
    case wait
}

struct Blueprint {
    let id: Int
    
    let oreRobotCost: Int
    
    let clayRobotCost: Int
    
    let obsidianRobotOreCost: Int
    let obsidianRobotClayCost: Int
    
    let geodeRobotOreCost: Int
    let geodeRobotObsidianCost: Int
    
    func costToBuild(robot: Resource) -> [Resource: Int] {
        switch robot {
        case .ore:
            return [.ore: oreRobotCost]
        case .clay:
            return [.ore: clayRobotCost]
        case .obsidian:
            return [.ore: obsidianRobotOreCost, .clay: obsidianRobotClayCost]
        case .geode:
            return [.ore: geodeRobotOreCost, .obsidian: geodeRobotObsidianCost]
        }
    }
}

var blueprints = [Blueprint]()

let filePath = "/Users/grayson/code/advent_of_code/2022/day_nineteen/test.txt"
guard let filePointer = fopen(filePath, "r") else {
    preconditionFailure("Could not open file at \(filePath)")
}
var lineByteArrayPointer: UnsafeMutablePointer<CChar>?
defer {
    fclose(filePointer)
    lineByteArrayPointer?.deallocate()
}
var lineCap: Int = 0
while getline(&lineByteArrayPointer, &lineCap, filePointer) > 0 {
    let line = String(cString:lineByteArrayPointer!)
    
    let id = Int(line.firstMatch(of: #/print (\d+)/#)!.output.1)!
    let oreRobotCost = Int(line.firstMatch(of: #/ore robot.+?(\d+)/#)!.output.1)!
    let clayRobotCost = Int(line.firstMatch(of: #/clay robot.+?(\d+)/#)!.output.1)!
    
    let obsidianRobotMatch = line.firstMatch(of: #/obsidian robot.+?(\d+).+?(\d+)/#)!.output
    let obsidianRobotOreCost = Int(obsidianRobotMatch.1)!
    let obsidianRobotClayCost = Int(obsidianRobotMatch.2)!
    
    let geodeRobotMatch = line.firstMatch(of: #/geode robot.+?(\d+).+?(\d+)/#)!.output
    let geodeRobotOreCost = Int(geodeRobotMatch.1)!
    let geodeRobotObsidianCost = Int(geodeRobotMatch.2)!
    
    let blueprint = Blueprint(id: id,
                              oreRobotCost: oreRobotCost,
                              clayRobotCost: clayRobotCost,
                              obsidianRobotOreCost: obsidianRobotOreCost,
                              obsidianRobotClayCost: obsidianRobotClayCost,
                              geodeRobotOreCost: geodeRobotOreCost,
                              geodeRobotObsidianCost: geodeRobotObsidianCost)
    
    blueprints.append(blueprint)
}

func timeToReceive(_ number: Int,
                   resource: Resource,
                   given currentRobots: [Resource: Int],
                   blueprint: Blueprint) -> Int {
    
    // is this method even needed??
//    currentRobots[resource, default: 0]
    
    return 0
}

func timeToBuild(robot: Resource,
                 given currentResources: [Resource: Int],
                 and currentRobots: [Resource: Int],
                 blueprint: Blueprint) -> Int {
    var timeNeeded = 0
    
    let resourcesRequired = blueprint.costToBuild(robot: robot)
    resourcesRequired.forEach { resource in
        let delta = currentResources[resource.key, default: 0] - resource.value
        
        // calculate the time here
        if delta < 0 {
            // should we require that we have the necessary robots? i think so
            var time = Int(delta.magnitude) / currentRobots[resource.key]!
            if time > 1 {
                time += Int(delta.magnitude) % currentRobots[resource.key]!
            }
            
            timeNeeded += time
        }
    }
    
    return timeNeeded
}

func getMaxGeodes(currentTime: Int, currentResources: [Resource: Int], currentRobots: [Resource: Int]) -> Int {
    var maxGeodes = 0
    
    for robotToBuild in Resource.allCases {
        // check if we _can_ build this?
        if !currentRobots.keys.contains(robotToBuild.neededResources) {
            continue
        }
        
        // check if we have enough time to build the robot
        //...
        
        // calculate the next things for the function and call it
        // maxG = max(maxG, next function call)
    }
    
    return maxGeodes
}
