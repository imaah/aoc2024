import argv
import file_streams/file_stream.{type FileStream}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder

type InputType =
  Dict(Int, Dict(Int, String))

fn read_line(line: String) -> Dict(Int, String) {
  string.trim(line)
  |> string.to_graphemes()
  |> list.index_map(fn(s, i) { #(i, s) })
  |> dict.from_list()
}

fn read_lines(stream: FileStream, y: Int, input: InputType) -> InputType {
  case file_stream.read_line(stream) {
    Ok(line) ->
      read_lines(stream, y + 1, dict.insert(input, y, read_line(line)))
    _ -> input
  }
}

fn str_matches_dir(
  d: InputType,
  needle: String,
  pos: #(Int, Int),
  dir: #(Int, Int),
) -> Bool {
  case string.pop_grapheme(needle) {
    Error(_) -> True
    Ok(#(c, rest)) -> {
      {
        use line <- result.try(dict.get(d, pos.1))
        use char <- result.try(dict.get(line, pos.0))

        case c == char {
          True -> str_matches_dir(d, rest, #(pos.0 + dir.0, pos.1 + dir.1), dir)
          False -> False
        }
        |> Ok()
      }
      |> result.unwrap(False)
    }
  }
}

fn str_count_dir(d: InputType, needle: String, dir: #(Int, Int)) -> Int {
  let iter_y = yielder.range(from: 0, to: dict.size(d))
  let iter_x =
    yielder.range(
      from: 0,
      to: dict.size(result.lazy_unwrap(dict.get(d, 0), fn() { dict.new() })),
    )

  yielder.map(iter_y, fn(y) {
    yielder.map(iter_x, fn(x) {
      bool.to_int(str_matches_dir(d, needle, #(x, y), dir))
    })
    |> yielder.reduce(fn(acc, v) { acc + v })
    |> result.unwrap(0)
  })
  |> yielder.reduce(fn(acc, v) { acc + v })
  |> result.unwrap(0)
}

fn part_1(input: InputType) -> Int {
  [#(1, 1), #(-1, -1), #(1, -1), #(-1, 1), #(1, 0), #(0, 1), #(-1, 0), #(0, -1)]
  |> list.map(fn(dir) { str_count_dir(input, "XMAS", dir) })
  |> int.sum()
}

fn part_2(input: InputType) -> Int {
  let iter_y = yielder.range(from: 0, to: dict.size(input))
  let iter_x =
    yielder.range(
      from: 0,
      to: dict.size(result.lazy_unwrap(dict.get(input, 0), fn() { dict.new() })),
    )

  yielder.map(iter_y, fn(y) {
    yielder.map(iter_x, fn(x) {
      bool.to_int(
        {
          str_matches_dir(input, "MAS", #(x, y), #(1, 1))
          || str_matches_dir(input, "SAM", #(x, y), #(1, 1))
        }
        && {
          str_matches_dir(input, "MAS", #(x + 2, y), #(-1, 1))
          || str_matches_dir(input, "SAM", #(x + 2, y), #(-1, 1))
        },
      )
    })
    |> yielder.reduce(fn(acc, v) { acc + v })
    |> result.unwrap(0)
  })
  |> yielder.reduce(fn(acc, v) { acc + v })
  |> result.unwrap(0)
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename, ..] -> filename
    _ -> "input.txt"
  }
  let assert Ok(stream) = file_stream.open_read(filename)
  // use this line if the order of the input is important!
  // let lines = list.reverse(read_lines(stream, []))
  let lines = read_lines(stream, 0, dict.new())

  io.println("part1={" <> int.to_string(part_1(lines)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines)) <> "}")
}
