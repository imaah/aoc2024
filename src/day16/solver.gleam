import argv
import file_streams/file_stream.{type FileStream}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/set.{type Set}
import gleam/string
import graph.{type Graph, type Node}

type Input =
  Graph(graph.Undirected, Int, Vec2)

type Vec2 {
  Vec2(x: Int, y: Int)
}

const dirs: List(Vec2) = [
  Vec2(x: -1, y: 0),
  Vec2(x: 1, y: 0),
  Vec2(x: 0, y: -1),
  Vec2(x: 0, y: 1),
]

fn read_lines(stream: FileStream, y: Int) -> #(Dict(Vec2, String), Int) {
  case file_stream.read_line(stream) {
    Ok(line) -> {
      let #(map, max_y) = read_lines(stream, y + 1)
      #(
        line
          |> string.trim()
          |> string.to_graphemes()
          |> list.index_map(fn(v, i) { #(Vec2(x: i, y: y), v) })
          |> dict.from_list()
          |> dict.merge(map),
        max_y,
      )
    }
    _ -> #(dict.new(), y - 1)
  }
}

fn vec2_add(a: Vec2, b: Vec2) -> Vec2 {
  Vec2(x: a.x + b.x, y: a.y + b.y)
}

fn vec2_inverse(a: Vec2) -> Vec2 {
  Vec2(x: -a.x, y: -a.y)
}

fn find_intersection(
  pos: Vec2,
  dir: Vec2,
  map: Dict(Vec2, String),
  depth: Int,
) -> Result(Node(Vec2), Int) {
  case dict.get(map, pos) {
    Ok("#") | Error(Nil) -> Error(depth)
    Ok(".") | Ok("S") | Ok("E") -> {
      list.filter_map(dirs, fn(d) {
        case dict.get(map, vec2_add(pos, d)) {
          Ok("#") -> Error(Nil)
          Ok(".") | Ok("S") | Ok("E") -> Ok(d)
          _ -> Error(Nil)
        }
      })
    }
    _ -> panic
  }
}

fn make_graph(
  g: Input,
  pos: Vec2,
  map: Dict(Vec2, String),
  visited: Set(Vec2),
) -> Input {
  use <- bool.guard(set.contains(visited, pos), g)

  case dict.get(map, pos) {
    Ok("#") -> g
    Ok("." as s) | Ok("S" as s) | Ok("E" as s) -> {
      todo
    }
    _ -> panic
  }
}

fn parse_input(map: Dict(Vec2, String)) -> Input {
  make_graph(graph.new(), Vec2(1, 1), map, set.new())
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

  let #(lines, max_y) = read_lines(stream, 0)
  let input = parse_input()

  io.println("part1={" <> int.to_string(part_1(input)) <> "}")
  io.println("part2={" <> int.to_string(part_2(input)) <> "}")
}
