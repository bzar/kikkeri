{reverse, sum, empty, all, fold, concat-map, flatten, span, Obj, sort-by, head} = require 'prelude-ls'

# [[String]] -> Bool
in-order = (xss) -> all (-> it.length == 1), xss

# [[String] -> Data -> [[String]]] -> Data -> [String] -> [[String]]
order-by-one = (fs, d, xs) -->
  | xs.length < 2 => [xs]
  | otherwise =>
    fold ((ys, f) -> if ys.length == 1 then f(ys[0], d) else ys), [xs], fs

# [[String] -> Data -> [[String]]] -> [[String]] -> Data  -> [[String]]
order-by-many = (fs, xss, d) ->
  let yss = concat-map order-by-one(fs, d), xss
    switch
    | yss.length == xss.length => flatten yss
    | in-order yss => flatten yss
    | otherwise => order-by-many fs, yss, d

# [[String] -> Data -> [[String]]] -> [String] -> Data -> [String]
multisort = (fs, xs, d) -> order-by-many fs, [xs], d

# a -> [String] -> [[String]]
segment-by = (f, xs) -->
  | empty xs => []
  | xs.length == 1 => [xs]
  | otherwise =>
    f0 = f(head xs)
    s = span (-> f(it) == f0), xs
    [s[0]] ++ segment-by(f, s[1])


module.exports = {
  multisort
  segment-by
}

