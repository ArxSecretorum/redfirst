package main

type Box struct{}

func (b *Box) deadMethodName() int {
	return 1
}
