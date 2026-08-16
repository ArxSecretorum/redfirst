package main

// DeadThing is documented but never constructed.
type DeadThing struct{}

func (d DeadThing) Method() {}

type LiveThing struct{}

func use() { _ = LiveThing{} }

func main() { use() }
