import argv
import file_streams/file_stream.{type FileStream}
import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type Position {
  Position(x: Float, y: Float)
}

type Prize {
  Prize(a: Position, b: Position, prize: Position)
}

type Input =
  List(Prize)

fn parse(line: String) -> Position {
  let assert Ok(#(_, pos)) = string.split_once(string.trim(line), ": ")
  let assert Ok(#(x, y)) = string.split_once(pos, ", ")

  let assert Ok(x) = int.parse(string.drop_start(x, 2))
  let assert Ok(y) = int.parse(string.drop_start(y, 2))
  Position(int.to_float(x), int.to_float(y))
}

fn read_prize(stream: FileStream) -> Result(Prize, Nil) {
  let lines =
    result.all([
      file_stream.read_line(stream),
      file_stream.read_line(stream),
      file_stream.read_line(stream),
    ])

  case lines {
    Ok([line_a, line_b, line_prize]) -> {
      let _ = file_stream.read_line(stream)
      Ok(Prize(a: parse(line_a), b: parse(line_b), prize: parse(line_prize)))
    }
    _ -> Error(Nil)
  }
}

fn read_lines(stream: FileStream) -> Input {
  case read_prize(stream) {
    Ok(line) -> [line, ..read_lines(stream)]
    _ -> []
  }
}

fn is_int(f: Float) -> Bool {
  int.to_float(float.truncate(f)) == f
}

fn solve(prize: Prize) -> Result(#(Int, Int), Nil) {
  let det = prize.a.x *. prize.b.y -. prize.b.x *. prize.a.y

  use <- bool.guard(det == 0.0, Error(Nil))

  let a = { prize.b.y *. prize.prize.x -. prize.b.x *. prize.prize.y } /. det
  let b = { prize.a.x *. prize.prize.y -. prize.a.y *. prize.prize.x } /. det

  use <- bool.guard(!is_int(a) || !is_int(b), Error(Nil))

  Ok(#(float.truncate(a), float.truncate(b)))
}

fn part_1(input: Input) -> Int {
  input
  |> list.filter_map(solve)
  |> list.map(fn(v) { 3 * v.0 + v.1 })
  |> int.sum()
}

fn part_2(input: Input) -> Int {
  input
  |> list.map(fn(v) {
    Prize(
      ..v,
      prize: Position(
        v.prize.x +. 10_000_000_000_000.0,
        v.prize.y +. 10_000_000_000_000.0,
      ),
    )
  })
  |> list.filter_map(solve)
  |> list.map(fn(v) { 3 * v.0 + v.1 })
  |> int.sum()
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
