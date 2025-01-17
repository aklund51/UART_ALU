import serial
import time
import threading

# Opcodes
ECHO_OPCODE = 0xEC
RESERVED = 0x00

# Specify the USB port and baud rate
usb_port = "/dev/ttyUSB2"  # Change this to your USB device path
baud_rate = 9600  # Adjust this to match your device's configuration
ser = serial.Serial(usb_port, baud_rate, timeout=1)

def create_packet(opcode, data):
    packet_len = len(data) + 4
    lsb_len = packet_len & 0xFF
    msb_len = (packet_len >> 8) & 0xFF

    # Combine all into packet
    packet = bytearray([opcode, RESERVED, lsb_len, msb_len]) + data
    return packet

def format_packet(packet):
    return " ".join(f"0x{byte:02x}" for byte in packet)

def echo(message):
    data = message.encode('utf-8')  # Convert to bytes
    packet = create_packet(ECHO_OPCODE, data)
    ser.write(packet)
    print(f"Sent: {format_packet(packet)}")

def receive_data():
    while True:
        if ser.in_waiting > 0:
            response = ser.read(ser.in_waiting)
            print(f"Received: {format_packet(response)}\n")
        time.sleep(0.1)


def main():
    try:
        # Open serial connection
        with ser:
            print(f"Connected to {usb_port} at {baud_rate} baud")

            # Start receiving thread
            thread = threading.Thread(target=receive_data, daemon=True)
            thread.start()

            try:
                while True:
                    message = input("Enter message to send (or 'exit' to quit): \n")
                    if message.lower() == 'exit':
                        break
                    echo(message)
            finally:
                ser.close()



    except serial.SerialException as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
