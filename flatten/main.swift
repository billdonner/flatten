//
//  main.swift
//  flatten
//
//  Created by bill donner on 5/29/23.
//

import Foundation
import ArgumentParser
import q20kshare


struct GameData : Codable, Hashable,Identifiable,Equatable {
  internal init(subject: String, challenges: [Challenge]) {
    self.subject = subject
    self.challenges = challenges //.shuffled()  //randomize
    self.id = UUID().uuidString
    self.generated = Date()
  }
  
  let id : String
  let subject: String
  let challenges: [Challenge]
  let generated: Date
}


func onelineCSV(from c:Challenge) -> String {
  var line = c.question + "," + c.topic + "," + c.hint + ","
  for a in c.answers {
    line += a + ","
  }
  line += c.correct + "," + c.explanation +  "," + (c.article ?? "") + "," + (c.image ?? "")
  return line
}

struct Flatten: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Flatten q20k JSON files into CSV for analysis by Excel or Numbers",
    discussion: "The input file must be an array of JSON Challenges, or a GameData file. The former comes out of Pumper, the latter out of Prepper")
  
  @Argument(  help: "The input json file URL")
  var inputTextFileURL: String
  
  @Argument(  help: "The output csv file URL")
  var outputCSVFileURL: String
  
  func parseInputSomehow(_ contents:Data) throws -> [Challenge] {
    var challenges:[Challenge] = []
    do{
      let gamedata =  try JSONDecoder().decode([GameData].self, from: contents)
      print("Decoded GameData file created \(gamedata[0].generated) will be flattened")
      for g in gamedata
      {
        challenges += g.challenges
      }
    }
    catch { // that didn't work, so try this
      do{
        challenges =  try Challenge.decodeArrayFrom(data: contents)
      }
      catch {
        // all failed
        print(">Flatten: the input at \(inputTextFileURL) could not be decoded \(error)")
      }
    }
    return []
  }
  
  func flatten_essence(_ outputCSVFile: URL, _ inputTextFile: URL) throws {
    var outputHandle:FileHandle
    outputHandle = try FileHandle(forWritingTo: outputCSVFile)
    let contents = try String(contentsOf: inputTextFile)
    let challenges = try parseInputSomehow(contents.data(using: .utf8)!)
    if challenges == [] { return}
    for challenge in challenges {
      let x = onelineCSV(from:challenge)
      outputHandle.write(x.data(using: .utf8)!)
    }
    try outputHandle.close()
  }
  
  func run() throws {
    guard let inputTextFile = URL(string: inputTextFileURL),
          let outputCSVFile = URL(string: outputCSVFileURL) else {
      throw ValidationError("Input and substitutions file URLs must be valid")
    }
    let start_time = Date()
    print("Command Line: \(CommandLine.arguments) \n")
    try flatten_essence(outputCSVFile, inputTextFile)
    let elapsed = Date().timeIntervalSince(start_time)
    print("Elapsed \(elapsed) secs")
  }
}

Flatten.main()


