package main

import (
	"github.com/rivo/tview"
)

func NewTUI() *tview.Application {
	app := tview.NewApplication()
	box := tview.NewBox().SetBorder(true).SetTitle("Hello, tview!")
	app.SetRoot(box, true)
	return app
}
