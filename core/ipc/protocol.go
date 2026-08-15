package ipc 

import "encoding/json"

type Event struct{
	Type string							`json:"type"`
	Payload json.RawMessage	`json:"payload"`
}

type Action struct {
	Name string						`json:"name"`
	Args json.RawMessage 	`json:"args"`
}
