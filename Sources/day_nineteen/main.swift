import Darwin
import Foundation

var log = false

enum Resource: CaseIterable, CustomStringConvertible {
    case ore
    case clay
    case obsidian
    case geode

    static let emptyDict: [Resource: Int] = [.ore: 0, .clay: 0, .obsidian: 0, .geode: 0]

    private static let oreResourceList: [Resource] = [.ore]
    private static let oreAndClayResourceList: [Resource] = [.ore, .clay]
    private static let oreAndObsidianResourceList: [Resource] = [.ore, .obsidian]
    
    var neededResources: [Resource] {
        switch self {
        case .ore:
            return Resource.oreResourceList
        case .clay:
            return Resource.oreResourceList
        case .obsidian:
            return Resource.oreAndClayResourceList
        case .geode:
            return Resource.oreAndObsidianResourceList
        }
    }

    var description: String {
        switch self {
        case .ore:
            return "ore"
        case .clay:
            return "clay"
        case .obsidian:
            return "obsidian"
        case .geode:
            return "geode"
        }
    }
}

struct Blueprint {
    let id: Int
    
    let oreRobotCost: Int
    
    let clayRobotCost: Int
    
    let obsidianRobotOreCost: Int
    let obsidianRobotClayCost: Int
    
    let geodeRobotOreCost: Int
    let geodeRobotObsidianCost: Int

    func maxRequirement(for resource: Resource) -> Int {
        switch resource {
        case .ore:
            return max(oreRobotCost, clayRobotCost, obsidianRobotOreCost, geodeRobotOreCost)
        case .clay:
            return obsidianRobotClayCost
        case .obsidian:
            return geodeRobotObsidianCost
        case .geode:
            return .max
        }
    }
    
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

    func timeToGeode(robots: [Resource: Int], adding: Int = 0, of: Resource = .ore) -> Int {
        let additionalObsidian = of == .obsidian ? adding : 0
        let additionalClay = of == .clay ? adding : 0
        let additionalOre = of == .ore ? adding : 0

        let timeToObsidian = self.geodeRobotObsidianCost / (1 + robots[.obsidian]! + additionalObsidian)
        let timeToClay = self.obsidianRobotClayCost / (1 + robots[.clay]! + additionalClay)
        let timeToOre = (self.geodeRobotOreCost + self.obsidianRobotOreCost + self.clayRobotCost) / (1 + robots[.ore]! + additionalOre)
        return timeToObsidian + timeToClay + timeToOre
    }

    typealias RobotToBuildToOutcome = [Resource: (timeNeeded: Int, resourcesMade: [Resource: Int])]
    typealias RobotsAvailableToRobotToBuildToOutcome = [[Resource: Int]: RobotToBuildToOutcome]
    typealias ResourcesToRobotsAvailableToRobotToBuildToOutcome = [[Resource: Int]: RobotsAvailableToRobotToBuildToOutcome]

    // dictionary from resources needed to robots available to (robot to build) to (time needed, resources made)
    var cache = ResourcesToRobotsAvailableToRobotToBuildToOutcome()
}

var blueprints = [Blueprint]()

let filePath = "/Users/graysonsmith/code/advent_of_code/2022/doc22_day_nineteen/test.txt"
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

func effortToBuild(robot: Resource,
                   given currentResources: [Resource: Int],
                   withRobots currentRobots: [Resource: Int],
                   blueprint: inout Blueprint) -> (timeTaken: Int,
                                             resourcesTaken: [Resource: Int],
                                             resourcesMade: [Resource: Int]) {
    var timeNeeded = 0
    var resourcesMade = Resource.emptyDict
    
    let resourcesRequired = blueprint.costToBuild(robot: robot)

//    if let outcome = blueprint.cache[currentRobots]?[currentResources]?[robot] {
//        return (timeTaken: outcome.timeNeeded,
//                resourcesTaken: resourcesRequired,
//                resourcesMade: outcome.resourcesMade)
//    }

    resourcesRequired.forEach { resource in
        let delta = currentResources[resource.key]! - resource.value
        
        // calculate the time here
        if delta < 0 {
            // should we require that we have the necessary robots? i think so
            var time = Int(delta.magnitude) / currentRobots[resource.key]!
            if time >= 1 {
                time += Int(delta.magnitude) % currentRobots[resource.key]!
            }
            
            timeNeeded += time
        }
    }

    timeNeeded += 1 // increment for time to build the robot

    currentRobots.forEach { currentRobot in
        resourcesMade[currentRobot.key] = timeNeeded * currentRobot.value
    }

//    if blueprint.cache[currentRobots] == nil {
//        blueprint.cache[currentRobots] = [currentResources: [robot: (timeNeeded: timeNeeded, resourcesMade: resourcesMade)]]
//    } else {
//        if blueprint.cache[currentRobots]![currentResources] == nil {
//            blueprint.cache[currentRobots]![currentResources] = [robot: (timeNeeded: timeNeeded, resourcesMade: resourcesMade)]
//        } else {
//            blueprint.cache[currentRobots]![currentResources]![robot] = (timeNeeded: timeNeeded, resourcesMade: resourcesMade)
//        }
//    }
    
    return (timeTaken: timeNeeded, resourcesTaken: resourcesRequired, resourcesMade: resourcesMade)
}

func getMaxGeodes(currentTime: Int,
                  currentResources: [Resource: Int],
                  currentRobots: [Resource: Int],
                  blueprint: inout Blueprint) -> Int {
    var maxGeodes = 0

    for robotToBuild in Resource.allCases {
        // check if we _can_ build this?
        var weCannotBuildIt = false
        for neededResource in robotToBuild.neededResources {
            if currentRobots[neededResource] == 0 {
                weCannotBuildIt = true
                break
            }
        }
        if weCannotBuildIt {
//            if log { print("  no material-producing robot available") }
            continue
        }

        // if we already have X of these robots where X == max robot req for this resource...don't need to build
        let maxReq = blueprint.maxRequirement(for: robotToBuild)
        if currentRobots[robotToBuild]! >= maxReq {
//            if log { print("  no need for more") }
            continue
        }

        let minutesLeft = (24 - currentTime)
        let resourcesByTheEnd = (currentRobots[robotToBuild]! * minutesLeft) + currentResources[robotToBuild]!
        if robotToBuild != .geode && resourcesByTheEnd >= (minutesLeft * maxReq) {
            continue
        }

        if currentTime >= 22 && robotToBuild != .geode {
//            if log { print("  probably not worth it") }
            continue
        }

        var nextRobots = currentRobots
        nextRobots[robotToBuild] = nextRobots[robotToBuild]! + 1

        // check if we have enough time to build a geode
//        if nextRobots[.geode] == 0 {
//            let newTimeToGeode = currentTime + blueprint.timeToGeode(robots: nextRobots)
//            if newTimeToGeode >= 24 {
//                printStatement += "  not enough time to build a geode machine \(newTimeToGeode)\n"
//                if log { print(printStatement) }
//                continue
//            }
//        }

        // check if we have enough time to build the robot
        let buildEffort = effortToBuild(robot: robotToBuild,
                                        given: currentResources,
                                        withRobots: currentRobots,
                                        blueprint: &blueprint)
        let newTime = currentTime + buildEffort.timeTaken
        if newTime >= 24 {
//            if log { print("  would run out of time") }
            continue
        }
        
        // calculate the next things for the function and call it
        // maxG = max(maxG, next function call)
        var nextResources = Resource.emptyDict
        for currentResource in currentResources {
            let used = buildEffort.resourcesTaken[currentResource.key, default: 0]
            let made = buildEffort.resourcesMade[currentResource.key, default: 0]
            if made < 0 {
                fatalError()
            }
            nextResources[currentResource.key] = currentResource.value - used + made
        }

        // geodes till end of time!!!! only from this change
        let nextGeodes = (24 - newTime) * (robotToBuild == .geode ? 1 : 0)

        if log {
            print("Calculating max at time=\(currentTime)")
            print("  currentResources=\(currentResources)")
            print("  currentRobots=\(currentRobots)")
            print("  eval building=\(robotToBuild)")
            print("    newTime=\(newTime)")
            print("    resourcesTaken=\(buildEffort.resourcesTaken)")
            print("    resourcesMade=\(buildEffort.resourcesMade)")
            print("    nextResources=\(nextResources)")
            print("    nextRobots=\(nextRobots)")
            print("    nextGeodes=\(nextGeodes)")
        }


        maxGeodes = max(maxGeodes, nextGeodes + getMaxGeodes(currentTime: newTime,
                                                             currentResources: nextResources,
                                                             currentRobots: nextRobots,
                                                             blueprint: &blueprint))
    }
    
    return maxGeodes
}

print(blueprints[0])

let currentResources = Resource.emptyDict
let currentRobots: [Resource: Int] = [.ore: 1, .clay: 0, .obsidian: 0, .geode: 0]

//let blueprint = blueprints[0]
//print(blueprint)

//let a =
//print(blueprints[0].timeToGeode(robots: [.ore: 1, .clay: 3, .obsidian: 0, .geode: 0], adding: 1, of: .clay))

print(getMaxGeodes(currentTime: 1, currentResources: currentResources, currentRobots: currentRobots, blueprint: &blueprints[1]))
