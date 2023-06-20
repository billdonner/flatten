//
//  main.swift
//  flatten
//
//  Created by bill donner on 5/29/23.
//

import Foundation
import ArgumentParser
import q20kshare


extension String {
  var fixup : String {
    return self.replacingOccurrences(of: ",", with: ";")
  }
}
func headerCSV() -> String {
  return "Question,Topic,Hint,Ans-1,Ans-2,Ans-3,Correct,Truth-1,Truth-2,Explanation,Article,Image\n"
  
}

func onelineCSV(from c:Challenge) -> String {
  let opinions = c.opinions
  var o1 = ""
  var o2 = ""
  if opinions.count>1 {
    o2 = "\(opinions[1].truth)"
  }
  if opinions.count>0 {
    o1 = "\(opinions[0].truth)"
  }
  var line = c.question.fixup + "," + c.topic.fixup + "," + c.hint.fixup + ","
  for a in c.answers.dropLast(max(0,c.answers.count-3)) {
    line += a.fixup + ","
  }
  line += c.correct.fixup + "," + o1 + "," + o2
  line += "," + (c.explanation?.fixup ?? "") +  ","
  line +=   (c.article?.fixup ?? "") + "," + (c.image?.fixup ?? "")
  return line + "\n" // need to separate
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
      let gamedata:[GameData] =  try JSONDecoder().decode([GameData].self, from: contents)
      print(">GameData file created \(gamedata[0].generated) will be flattened")
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
    return challenges
  }
  
  func flatten_essence(_ outputCSVFile: URL, _ inputTextFile: URL) throws {
   
    let contents = try String(contentsOf: inputTextFile)
    let challenges = try parseInputSomehow(contents.data(using: .utf8)!)
    if challenges == [] { print("No challenges in input"); return}
    let x = outputCSVFile.absoluteString.dropFirst(7) //remove file://
    var linecount = 0
    if (FileManager.default.createFile(atPath: String(x), contents: nil, attributes: nil)) {
   //   print("\(x) created successfully.")
    } else {
      print("\(x) not created."); return
    }
    let outputHandle = try FileHandle(forWritingTo: outputCSVFile)
    outputHandle.write(headerCSV().data(using:.utf8)!)
    for challenge in challenges {
      let x = onelineCSV(from:challenge)
      outputHandle.write(x.data(using: .utf8)!)
      linecount += 1
    }
    try outputHandle.close()
    print(">Wrote \(linecount) lines to \(x)")
  }
  
  func run() throws {
    guard let inputTextFile = URL(string: inputTextFileURL),
          let outputCSVFile = URL(string: outputCSVFileURL) else {
      throw ValidationError("Input and substitutions file URLs must be valid")
    }
    let start_time = Date()
    print(">Command Line: \(CommandLine.arguments) \n")
    try flatten_essence(outputCSVFile, inputTextFile)
    let elapsed = Date().timeIntervalSince(start_time)
    print(">Elapsed \(elapsed) secs")
  }
}

Flatten.main()


