import argv
import file_streams/file_stream
import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type Op {
  Do
  Dont
  Mul(right: Int, left: Int)
}

type InputType =
  List(Op)

fn parse_int(val: Int, line: String) -> Result(#(Int, String), Nil) {
  use #(c, rest) <- result.try(string.pop_grapheme(line))
  case c {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> {
      let c = result.unwrap(int.parse(c), 0)
      parse_int(val * 10 + c, rest)
    }
    "," | ")" -> Ok(#(val, rest))
    _ -> Error(Nil)
  }
}

fn parse(str: String, input: InputType) -> InputType {
  case str {
    "do()" <> rest -> parse(rest, [Do, ..input])
    "don't()" <> rest -> parse(rest, [Dont, ..input])
    "mul(" <> rest -> {
      {
        use #(right, rest) <- result.try(parse_int(0, rest))
        use #(left, rest) <- result.try(parse_int(0, rest))
        Ok(parse(rest, [Mul(right: right, left: left), ..input]))
      }
      |> result.lazy_unwrap(fn() { parse(string.drop_start(str, 9), input) })
    }
    "" -> input
    _ -> parse(string.drop_start(str, 1), input)
  }
}

fn read_input(stream: file_stream.FileStream, input: InputType) -> InputType {
  case file_stream.read_line(stream) {
    Ok(line) -> read_input(stream, list.flatten([parse(line, []), input]))
    _ -> input
  }
}

fn part_1(input: InputType) -> Int {
  list.filter_map(input, fn(op) {
    case op {
      Mul(right, left) -> Ok(right * left)
      _ -> Error(Nil)
    }
  })
  |> list.reduce(fn(acc, v) { acc + v })
  |> result.unwrap(0)
}

fn part_2(input: InputType, do: Bool) -> Int {
  case input {
    [Mul(right, left), ..rest] ->
      part_2(rest, do) + bool.to_int(do) * right * left
    [Dont, ..rest] -> part_2(rest, False)
    [Do, ..rest] -> part_2(rest, True)
    [] -> 0
  }
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename] -> filename
    _ -> "input.txt"
  }

  let assert Ok(stream) = file_stream.open_read(filename)
  let lines = list.reverse(read_input(stream, []))

  io.println("part1={" <> int.to_string(part_1(lines)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines, True)) <> "}")
}
