package main

import (
	"fmt"
	"log"

	zmq "github.com/pebbe/zmq4"
	"google.golang.org/protobuf/proto"

	fifov1 "github.com/tanovicm/fifo-buffer/gen/go/fifo/v1"
	pb "github.com/tanovicm/fifo-buffer/gen/go/fifo/v1"
)

type command struct {
	req  *pb.Request
	resp chan *pb.Response
}

func Buffer(commands chan command) {
	queue := []string{}

	for cmd := range commands {
		switch req := cmd.req.Request.(type) {

		case *fifov1.Request_Push:
			queue = append(queue, req.Push.Element)
			cmd.resp <- &fifov1.Response{
				Response: &fifov1.Response_Push{
					Push: &fifov1.PushResponse{
						Success: true,
						Message: "Element pushed",
					},
				},
			}

		case *fifov1.Request_Pull:
			if len(queue) == 0 {
				cmd.resp <- &fifov1.Response{
					Response: &fifov1.Response_Pull{
						Pull: &fifov1.PullResponse{
							Success: false,
							Message: "Queue is empty",
						},
					},
				}
			} else {
				elem := queue[0]
				queue = queue[1:]
				cmd.resp <- &fifov1.Response{
					Response: &fifov1.Response_Pull{
						Pull: &fifov1.PullResponse{
							Success: true,
							Element: elem,
							Message: "Pulled successfully",
						},
					},
				}
			}

		case *fifov1.Request_Size:
			cmd.resp <- &fifov1.Response{
				Response: &fifov1.Response_Size{
					Size: &fifov1.SizeResponse{
						Size: int32(len(queue)),
					},
				},
			}

		default:
			cmd.resp <- &fifov1.Response{
				Response: &fifov1.Response_Push{
					Push: &fifov1.PushResponse{
						Success: false,
						Message: "Unknown request type",
					},
				},
			}
		}
	}
}

func main() {
	commands := make(chan command)
	go Buffer(commands)

	socket, err := zmq.NewSocket(zmq.REP)
	if err != nil {
		log.Fatal("ZeroMQ socket error:", err)
	}
	defer socket.Close()

	err = socket.Bind("tcp://*:5555")
	if err != nil {
		log.Fatal("Bind error:", err)
	}

	fmt.Println("Server is listening on tcp://*:5555")

	for {
		msgBytes, err := socket.RecvBytes(0)
		if err != nil {
			log.Println("Receive error:", err)
			continue
		}

		var req pb.Request
		if err := proto.Unmarshal(msgBytes, &req); err != nil {
			log.Println("Unmarshal error:", err)
			continue
		}

		respChan := make(chan *pb.Response)
		commands <- command{req: &req, resp: respChan}
		resp := <-respChan

		outBytes, err := proto.Marshal(resp)
		if err != nil {
			log.Println("Marshal error:", err)
			continue
		}

		socket.SendBytes(outBytes, 0)
	}
}
