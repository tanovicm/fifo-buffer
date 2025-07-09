import zmq
import sys
import os

current_dir = os.path.dirname(__file__)
gen_path = os.path.join(current_dir, 'gen')
sys.path.append(gen_path)

print(f"Looking for protobuf files in: {gen_path}")
print(f"Files exist: {os.path.exists(gen_path)}")
if os.path.exists(gen_path):
    print(f"Contents: {os.listdir(gen_path)}")

try:
    from fifo.v1 import fifo_pb2
    print("✓ Successfully imported protobuf files")
except ImportError as e:
    print(f"Error: {e}")
    print("Please generate protobuf files first.")
    print("Run: make python")
    sys.exit(1)

class FifoClient:
    def __init__(self, endpoint=None):
        if endpoint is None:
            endpoint = os.getenv('FIFO_SERVER_ENDPOINT', 'tcp://localhost:5555')
        
        self.context = zmq.Context()
        self.socket = self.context.socket(zmq.REQ)
        self.socket.connect(endpoint)
        print(f"Connected to FIFO server at: {endpoint}")
        
    def push(self, element):
        request = fifo_pb2.Request()
        request.push.element = element
        
        self.socket.send(request.SerializeToString())
        
        response_data = self.socket.recv()
        response = fifo_pb2.Response()
        response.ParseFromString(response_data)
        
        return response.push.success, response.push.message
    
    def pull(self):
        request = fifo_pb2.Request()
        request.pull.CopyFrom(fifo_pb2.PullRequest())
        
        self.socket.send(request.SerializeToString())
        
        response_data = self.socket.recv()
        response = fifo_pb2.Response()
        response.ParseFromString(response_data)
        
        return response.pull.success, response.pull.element, response.pull.message
    
    def size(self):
        request = fifo_pb2.Request()
        request.size.CopyFrom(fifo_pb2.SizeRequest())
        
        self.socket.send(request.SerializeToString())
        
        response_data = self.socket.recv()
        response = fifo_pb2.Response()
        response.ParseFromString(response_data)
        
        return response.size.size
    
    def close(self):
        self.socket.close()
        self.context.term()

def main():
    client = FifoClient()
    
    print("=== Mutex-Free FIFO Buffer Client Demo ===")
    print()
    
    try:
        size = client.size()
        print(f"Initial buffer size: {size}")
        print()
        
        elements = ["first", "second", "third", "fourth", "fifth"]
        print("Pushing elements:")
        for element in elements:
            success, message = client.push(element)
            print(f"  Push '{element}': {'✓' if success else '✗'} - {message}")
        
        print()
        
        size = client.size()
        print(f"Buffer size after pushing: {size}")
        print()
        
        print("Pulling elements:")
        for i in range(3):
            success, element, message = client.pull()
            if success:
                print(f"  Pull {i+1}: '✓' - Got: '{element}' - {message}")
            else:
                print(f"  Pull {i+1}: '✗' - {message}")
        
        print()
        
        size = client.size()
        print(f"Buffer size after pulling: {size}")
        print()
        
        print("Pulling remaining elements:")
        while True:
            success, element, message = client.pull()
            if success:
                print(f"  Got: '{element}' - {message}")
            else:
                print(f"  {message}")
                break
        
        print()
        
        size = client.size()
        print(f"Final buffer size: {size}")
        
    except KeyboardInterrupt:
        print("\nClient interrupted by user")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        client.close()
        print("Client closed")

if __name__ == "__main__":
    main()