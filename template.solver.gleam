import argv
import file_streams/file_stream.{type FileStream}
import gleam/int
import gleam/io

type Input =
  List(String)

fn read_lines(stream: FileStream) -> Input {
  case file_stream.read_line(stream) {
    Ok(line) -> [line, ..read_lines(stream)]
    _ -> input
  }
}

fn part_1(input: Input) -> Int {
  0
}

fn part_2(input: Input) -> Int {
  0
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename, ..] -> filename
    _ -> "input.txt"
  }
  let assert Ok(stream) = file_stream.open_read(filename)

  let lines = read_lines(stream)

  io.println("part1={" <> int.to_string(part_1(lines)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines)) <> "}")
}
