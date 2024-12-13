import argv
import file_streams/file_stream.{type FileStream}
import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import utils

type Position {
  Position(x: Int, y: Int)
}

type Region {
  Region(name: String, area: Int, perimeter: Int, sides: Int)
}

type Side {
  Up
  Down
  Left
  Right
}

type Input =
  List(Region)

fn read_lines(stream: FileStream) -> List(String) {
  case file_stream.read_line(stream) {
    Ok(line) -> [string.trim(line), ..read_lines(stream)]
    _ -> []
  }
}

fn string_at(s: String, i: Int) -> Result(String, Nil) {
  use <- bool.guard(i < 0, Error(Nil))
  string.drop_start(s, i)
  |> string.first()
}

fn get_sides(map: List(String), pos: Position, name: String) -> Set(Side) {
  get_dirs(pos)
  |> list.fold(set.new(), fn(acc, p) {
    case get_name(map, p.1) {
      Ok(n) if n == name -> acc
      _ -> set.insert(acc, p.0)
    }
  })
}

fn get_sides_with_name(
  map: List(String),
  pos: Position,
  name: String,
) -> Set(Side) {
  get_dirs(pos)
  |> list.fold(set.new(), fn(acc, p) {
    case get_name(map, p.1) {
      Ok(n) if n == name -> set.insert(acc, p.0)
      _ -> acc
    }
  })
}

fn get_name(map: List(String), pos: Position) -> Result(String, Nil) {
  use line <- result.try(utils.at_index(map, pos.y))
  string_at(line, pos.x)
}

fn get_dirs(from: Position) -> List(#(Side, Position)) {
  [
    #(Right, Position(from.x + 1, from.y)),
    #(Down, Position(from.x, from.y + 1)),
    #(Left, Position(from.x - 1, from.y)),
    #(Up, Position(from.x, from.y - 1)),
  ]
}

fn parse_region(
  map: List(String),
  pos: Position,
  region: Region,
  visited: Set(Position),
) -> Result(#(Region, Set(Position)), Bool) {
  use name <- result.try(get_name(map, pos) |> result.replace_error(True))

  let region = case region {
    Region(name: "", ..) as r -> Region(..r, name: name)
    _ -> region
  }

  use <- bool.guard(name != region.name, Error(True))
  use <- bool.guard(set.contains(visited, pos), Error(False))

  let region = Region(..region, area: region.area + 1)
  let visited = set.insert(visited, pos)

  let #(region, visited) =
    get_dirs(pos)
    |> list.fold(#(region, visited), fn(acc, p) {
      case parse_region(map, p.1, acc.0, acc.1) {
        Ok(#(region, visited)) -> {
          #(region, visited)
        }
        Error(True) -> #(
          Region(..acc.0, perimeter: { acc.0 }.perimeter + 1),
          acc.1,
        )
        _ -> acc
      }
    })

  let sides = get_sides(map, pos, name)

  let corners =
    [
      set.from_list([Up, Right]),
      set.from_list([Up, Left]),
      set.from_list([Down, Right]),
      set.from_list([Down, Left]),
    ]
    |> list.count(fn(s) { set.size(set.intersection(sides, s)) == 2 })

  let corners =
    corners
    + {
      [
        #(set.from_list([Left, Down]), Position(pos.x + 1, pos.y - 1)),
        #(set.from_list([Left, Up]), Position(pos.x + 1, pos.y + 1)),
        #(set.from_list([Right, Up]), Position(pos.x - 1, pos.y + 1)),
        #(set.from_list([Right, Down]), Position(pos.x - 1, pos.y - 1)),
      ]
      |> list.count(fn(s) {
        case get_name(map, s.1) {
          Ok(n) if n != name -> {
            set.size(set.intersection(get_sides_with_name(map, s.1, name), s.0))
            == 2
          }
          _ -> False
        }
      })
    }

  Ok(#(Region(..region, sides: region.sides + corners), visited))
}

fn parse_regions(in: List(String)) -> Input {
  let res =
    yielder.range(0, list.length(in) - 1)
    |> yielder.fold(#([], set.new()), fn(acc, y) {
      yielder.range(0, list.length(in) - 1)
      |> yielder.fold(acc, fn(acc, x) {
        let pos = Position(x, y)
        use <- bool.guard(set.contains(acc.1, pos), acc)
        case
          parse_region(
            in,
            pos,
            Region(name: "", area: 0, perimeter: 0, sides: 0),
            acc.1,
          )
        {
          Ok(#(region, visited)) -> {
            #([region, ..acc.0], visited)
          }
          Error(_) -> acc
        }
      })
    })

  res.0
}

fn part_1(input: Input) -> Int {
  list.fold(input, 0, fn(acc, r) { acc + r.area * r.perimeter })
}

fn part_2(input: Input) -> Int {
  list.fold(input, 0, fn(acc, r) { acc + r.area * r.sides })
}

pub fn main() {
  let filename = case argv.load().arguments {
    [filename, ..] -> filename
    _ -> "input.txt"
  }
  let assert Ok(stream) = file_stream.open_read(filename)

  let lines = {
    read_lines(stream)
    |> parse_regions()
  }
  io.println("part1={" <> int.to_string(part_1(lines)) <> "}")
  io.println("part2={" <> int.to_string(part_2(lines)) <> "}")
}
