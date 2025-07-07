import simd
import Accelerate
import UIKit
import RoomPlan

class CaculatorMatrix {
    var listWallAfterScan = [WallLong]()
    var listPointAfterScan = [Point]()
    var listWallNeedRemove = [WallLong]()
    static var shared = CaculatorMatrix()
    public var dataCapture: [DataCapture] = []
    
    public func createJSONCustom(finalResult: CapturedRoom) -> String {
        var pointList: [Point] = []
        var wallList: [WallLong] = []
        var countWall: Int = 1
        var countPoint: Int = 1
        let walls = finalResult.walls
        for wall in walls {
            let transform_matrix = wall.transform
            let dimension = wall.dimensions
            
            let wall_point = simd_float2x4([[-dimension[0]/2, 0, 0, 1],
                                            [dimension[0]/2, 0, 0, 1]])
            
            var projected_point_list: [Point] = []
            var wallValue = WallLong()
            
            for index in 0..<2 {
                let projected_point = transform_matrix * wall_point[index]
                let pointItem =  Point(id: "\(countPoint)", x: Int(projected_point[0] * 1000), y: Int(projected_point[2] * 1000))
                let finalPoint = pointItem.flipPointHorizontally()
                projected_point_list.append(finalPoint)
                if countPoint % 2 != 0 {
                    wallValue.start = finalPoint
                } else {
                    wallValue.end = finalPoint
                }
                
                countPoint += 1
            }
            
            wallValue.id = wall.identifier.uuidString
            wallValue.thickness = 200
            countWall += 1
            wallList.append(wallValue)
            pointList.append(contentsOf: projected_point_list)
        }
        
        
        
        let geometryData = Geometry(geometry: RoomObject(points: pointList, walls: wallList))
        
        let fianlGeometryData = handlePointDuplicate(geometryData: geometryData)
        wallList = fianlGeometryData.geometry.walls
        
        let doors = finalResult.doors
        for door in doors {
//            door { open in
//                print(open)
//            }
            let category = "\(door.category)"
            let isOpen = category.contains("isOpen: true")
            print("OPEN DOOR \(isOpen)")
            let transform_matrix = door.transform
            let dimension = door.dimensions
            
            let doorPoint = simd_float2x4([[-dimension[0]/2, 0, 0, 1],
                                           [dimension[0]/2, 0, 0, 1]])
            let projected_point = transform_matrix * doorPoint[0]
            var pointDoor =  Point(id: "\(countPoint)", x: Int(projected_point[0] * 1000), y: Int(projected_point[2] * 1000))
            pointDoor = pointDoor.flipPointHorizontally()
            if let index = wallList.firstIndex(where: {$0.id.contains((door.parentIdentifier?.uuidString ?? ""))}) {
                if let startPoint = pointList.first(where: {$0.id == wallList[index].start.id}) {
                    var doorItem = Door()
                    let offset = IntDistanceSquared(from: startPoint, to: pointDoor)
                    doorItem.offset = offset / 10000
                    doorItem.width = Int(door.dimensions.x * 1000)
                    //                    doorItem.side = "left"  //hard code
                    //                    doorItem.hinge = "left" // hard code
                    if isOpen {
                        doorItem.doorType = "doorOpening"
                    }
                    wallList[index].doors?.append(doorItem)
                    
                }
            }
        }
        
        let openings = finalResult.openings
        for opening in openings {
            let transform_matrix = opening.transform
            let dimension = opening.dimensions
            
            let openingPoint = simd_float2x4([[-dimension[0]/2, 0, 0, 1],
                                              [dimension[0]/2, 0, 0, 1]])
            let projected_point = transform_matrix * openingPoint[0]
            var pointOpening =  Point(id: "\(countPoint)", x: Int(projected_point[0] * 1000), y: Int(projected_point[2] * 1000))
            pointOpening = pointOpening.flipPointHorizontally()
            
            if let index = wallList.firstIndex(where: {$0.id.contains((opening.parentIdentifier?.uuidString ?? ""))}) {
                if let startPoint = pointList.first(where: {$0.id == wallList[index].start.id}) {
                    var openingItem = Opening()
                    let offset = IntDistanceSquared(from: startPoint, to: pointOpening)
                    openingItem.offset = offset / 10000
                    openingItem.width = Int(opening.dimensions.x * 1000)
                    wallList[index].openings?.append(openingItem)
                    
                }
            }
        }
        
        
        let windows = finalResult.windows
        for window in windows {
            let transform_matrix = window.transform
            let dimension = window.dimensions
            
            let windowPoint = simd_float2x4([[-dimension[0]/2, 0, 0, 1],
                                             [dimension[0]/2, 0, 0, 1]])
            
            let projected_point = transform_matrix * windowPoint[0]
            var pointWindow =  Point(id: "\(countPoint)", x: Int(projected_point[0] * 1000), y: Int(projected_point[2] * 1000))
            pointWindow = pointWindow.flipPointHorizontally()
            if let index = wallList.firstIndex(where: {$0.id.contains((window.parentIdentifier?.uuidString ?? ""))}) {
                if let startPoint = pointList.first(where: {$0.id == wallList[index].start.id}) {
                    var windowItem = Window()
                    let offset = IntDistanceSquared(from: startPoint, to: pointWindow)
                    windowItem.offset = offset / 10000
                    windowItem.width = Int(window.dimensions.x * 1000)
                    wallList[index].windows?.append(windowItem)
                }
            }
        }
        
        
        
        let finalWall: [Wall] = wallList.map({Wall(id: $0.id, start: $0.start.id, end: $0.end.id, thickness: $0.thickness, openings: $0.openings, doors: $0.doors, windows: $0.windows)})
        let geometryJSON = GeometryJSON(geometry: RoomJSONObject(points: fianlGeometryData.geometry.points, walls: finalWall))
        return converToJSon(point_list: geometryJSON)
        
    }
    
    func mergeClosePoints(_ points: [Point], threshold: Double = 200) -> [Point] {
        var mergedPoints = points
        var mergedIndices: Set<Int> = []
        
        for i in 0..<points.count {
            if mergedIndices.contains(i) {
                continue
            }
            
            for j in i+1..<points.count {
                if !mergedIndices.contains(j) && DoubleDistanceSquared(from: points[i], to: points[j]) < threshold {
                    // Merge points and update ID
                    let newPoint = Point(
                        id: points[i].id,
                        x: (points[i].x + points[j].x) / 2,
                        y: (points[i].y + points[j].y) / 2
                    )
                    mergedPoints[i] = newPoint
                    mergedIndices.insert(j)
                }
            }
        }
        
        // Filter out merged points
        let finalPoints = mergedPoints.enumerated().filter { !mergedIndices.contains($0.offset) }.map { $0.element }
        return finalPoints
    }
    
    func handlePointDuplicate(geometryData: Geometry) -> Geometry {
        var pointList = [Point]()
        
        for point in geometryData.geometry.points {
            if pointList.first(where: {$0.x == point.x && $0.y == point.y }) == nil {
                pointList.append(point)
            }
        }
        
        pointList = mergeClosePoints(pointList)
        self.listPointAfterScan = pointList
        var listWall = [WallLong]()
        for wall in geometryData.geometry.walls {
            var tempWall = wall
            if let start = pointList.first(where: {tempWall.start == $0}) {
                tempWall.start = start
            }
            if let end = pointList.first(where: {tempWall.end == $0}) {
                tempWall.end = end
            }
            listWall.append(tempWall)
        }
        listWallAfterScan = listWall
        
        //handle merge walls
        var alignedAdjacentWalls = self.findAlignedAdjacentWalls(alignedAdjacentWalls: listWall)
        
        let finalAlignedWalls = processWallList(alignedAdjacentWalls: alignedAdjacentWalls)
        
        return Geometry(geometry: RoomObject(points: listPointAfterScan, walls: finalAlignedWalls))
    }
    
    // finding wall to merge
    func findAlignedAdjacentWalls(alignedAdjacentWalls: [WallLong]) -> [WallLong] {
        listWallNeedRemove = []
        var finalWalls = [WallLong]()
        var updatedData = alignedAdjacentWalls
        
        let threshold = 10.0
        var seenWallIds = [String]()
        for wall1 in alignedAdjacentWalls {
            seenWallIds.append(wall1.id)
            let (s1, e1) = (wall1.start, wall1.end)
            
            for wall2 in alignedAdjacentWalls  where !seenWallIds.contains(wall2.id) {
                let (s2, e2) = (wall2.start, wall2.end)
                var mergeWall = WallLong()
                var fixWalls: [WallLong] = []
                var sharedPoint = ""
                let angle = calculateAngleBetween2Walls(wall1, wall2)
                let angleCondition = abs(angle) < threshold || abs(180 - angle) < threshold
                if angleCondition {
                    if s1 == s2 {
                        print("W1-2 \(wall1) - \(wall2)")
                        mergeWall.start = wall1.end
                        mergeWall.end = wall2.end
                        sharedPoint = s1.id
                        fixWalls = findFixWalls(pointId: s1.id, excludes: [wall1, wall2])
                        
                        listWallNeedRemove.append(wall1)
                        listWallNeedRemove.append(wall2)
                    } else if s1 == e2 {
                        print("W1-2 \(wall1) - \(wall2)")
                        mergeWall.start = wall1.end
                        mergeWall.end = wall2.start
                        sharedPoint = s1.id
                        fixWalls = findFixWalls(pointId: s1.id, excludes: [wall1, wall2])
                        
                        listWallNeedRemove.append(wall1)
                        listWallNeedRemove.append(wall2)
                    } else if e1 == s2 {
                        print("W1-2 \(wall1) - \(wall2)")
                        mergeWall.start = wall1.start
                        mergeWall.end = wall2.end
                        sharedPoint = e1.id
                        fixWalls = findFixWalls(pointId: e1.id, excludes: [wall1, wall2])
                        
                        listWallNeedRemove.append(wall1)
                        listWallNeedRemove.append(wall2)
                    } else if e1 == e2 {
                        print("W1-2 \(wall1) - \(wall2)")
                        mergeWall.start = wall1.start
                        mergeWall.end = wall2.start
                        sharedPoint = e1.id
                        fixWalls = findFixWalls(pointId: e1.id, excludes: [wall1, wall2])
                        
                        listWallNeedRemove.append(wall1)
                        listWallNeedRemove.append(wall2)
                    } else {
                        continue
                    }
                    mergeWall.id = "\(wall1.id) \(wall2.id)"
                    
                    for fixWall in fixWalls {
                        updatePointsToLieOnWalls(newMergeWall: mergeWall, fixWall: fixWall, sharedPoint: sharedPoint)
                    }
                    finalWalls.append(mergeWall)
                    
                }
            }
        }
        return finalWalls
    }
    
    func findFixWalls(pointId: String, excludes: [WallLong] = []) -> [WallLong] {
        var fixWalls: [WallLong] = []
        let walls = self.listWallAfterScan
        for fixWall in walls {
            // Exclude the merged walls
            if excludes.map({$0.id}).contains(fixWall.id) {
                continue
            }
            
            if fixWall.start.id == pointId {
                fixWalls.append(fixWall)
            } else if fixWall.end.id == pointId {
                fixWalls.append(fixWall)
            }
        }
        
        return fixWalls
    }
    
    func updatePointsToLieOnWalls(newMergeWall: WallLong, fixWall: WallLong, sharedPoint: String) {
        var updatedData = self.listWallAfterScan
        let points = listPointAfterScan
        var newWall = fixWall
        guard let point1 = points.first(where: { $0.id == newMergeWall.start.id }),
              let point2 = points.first(where: { $0.id == newMergeWall.end.id }),
              let point3 = points.first(where: { $0.id == fixWall.start.id }),
              let point4 = points.first(where: { $0.id == fixWall.end.id }),
              let sharedPoint = points.first(where: { $0.id == sharedPoint })else {
            return
        }
        
        if let intersectionPoint = findIntersection(point1: point1, point2: point2, point3: point3, point4: point4) {
            
            
            if newWall.start == sharedPoint {
                newWall.start = Point(id: sharedPoint.id, x: intersectionPoint.x, y: intersectionPoint.y)
            }
            
            if newWall.end == sharedPoint {
                newWall.end = Point(id: sharedPoint.id, x: intersectionPoint.x, y: intersectionPoint.y)
            }
            
            for (index, item) in self.listPointAfterScan.enumerated() {
                if item.id == newWall.start.id {
                    self.listPointAfterScan[index].x = newWall.start.x
                    self.listPointAfterScan[index].y = newWall.start.y
                }
                
                if item.id == newWall.end.id {
                    self.listPointAfterScan[index].x = newWall.end.x
                    self.listPointAfterScan[index].y = newWall.end.y
                }
            }
            
            if let index = self.listWallAfterScan.firstIndex(where: {$0.id == newWall.id}) {
                self.listWallAfterScan[index].start = newWall.start
                self.listWallAfterScan[index].end = newWall.end
            }
        }
        
    }
    
    func findIntersection(point1: Point,
                          point2: Point,
                          point3: Point,
                          point4: Point) -> (x: Int, y: Int)? {
        
        let m1 = Double(point2.y - point1.y) / Double(point2.x - point1.x)
        let b1 = Double(point1.y) - m1 * Double(point1.x)
        
        let m2 = Double(point4.y - point3.y) / Double(point4.x - point3.x)
        let b2 = Double(point3.y ) - m2 * Double(point3.x)
        
        if m1 == m2 {
            // Đường thẳng là song song, không có giao điểm
            return nil
        }
        
        let x = (b2 - b1) / (m1 - m2)
        let y = m1 * x + b1
        
        return (Int(x), Int(y))
    }
    
    // remove merged wall
    func processWallList(alignedAdjacentWalls: [WallLong]) -> [WallLong] {
        var newWallsList = listWallAfterScan
        
        for item in listWallNeedRemove {
            newWallsList = newWallsList.filter({$0.id != item.id})
        }
        newWallsList += alignedAdjacentWalls
        
        return newWallsList
    }
    
    func converToJSon(point_list: GeometryJSON) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            // Convert the object to JSON data
            let jsonData = try encoder.encode(point_list)
            
            // Convert JSON data to a string
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                return jsonString
            }
            
            
        } catch {
            print("Error encoding object to JSON: \(error)")
        }
        
        return ""
    }
    
    
    func calculateAngleBetween2Walls(_ wall1: WallLong, _ wall2: WallLong) -> Double {
        
        let vector1 = getVector(wall: wall1)
        let vector2 = getVector(wall: wall2)
        
        let dotProduct = vector1.0 * vector2.0 + vector1.1 * vector2.1
        
        let magnitude1 = (sqrt(Double(vector1.0 * vector1.0 + vector1.1 * vector1.1)))
        let magnitude2 = (sqrt(Double(vector2.0 * vector2.0 + vector2.1 * vector2.1)))
        
        let cosTheta = dotProduct / (magnitude1 * magnitude2)
        let theta = acos(CGFloat(cosTheta))
        
        // Convert angle from radians to degrees
        let angleInDegrees = theta * (180.0 / .pi)
        
        return angleInDegrees
    }
    
    func getVector(wall: WallLong) -> (Double, Double) {
        let startPoint = wall.start
        let endPoint = wall.end
        
        let x = Double(startPoint.x - endPoint.x)
        let y = Double(startPoint.y - endPoint.y)
        
        return (x, y)
    }
}


