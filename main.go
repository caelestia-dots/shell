package main

func main() {
	app := NewTUI()
	if err := app.Run(); err != nil {
		panic(err)
	}
}
