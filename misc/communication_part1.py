import serial
import time
import threading

# Opcodes
ECHO_OPCODE = 0xec
RESERVED = 0x00

def create_packet(opcode, data):
    packet_len = len(data) + 4
    lsb_len = packet_len & 0xFF
    msb_len = (packet_len >> 8) & 0xFF

    # Combine all into packet
    packet = bytearray([opcode, RESERVED, lsb_len, msb_len]) + data
    return packet

def echo(ser, message):
    data = bytearray(message.encode('utf-8'))
    packet = create_packet(ECHO_OPCODE, data)
    ser.write(packet)
    print(f"Sent packet: {packet.hex()}")

def read_data(ser, expected_data=None):
    while True:
        if ser.in_waiting:
            received = ser.read(ser.in_waiting)
            print(f"Received (hex): {received.hex()}")
            if expected_data:
                if received == expected_data:
                    print("PASS: Echo response matches sent data")
                else:
                    print("FAIL: Echo response does not match sent data")
        time.sleep(0.1)

def main():
    # Specify the USB port and baud rate
    usb_port = "/dev/ttyUSB1"  # Change this to your USB device path
    baud_rate = 9600  # Adjust this to match your device's configuration

    try:
        # Open serial connection
        with serial.Serial(usb_port, baud_rate, timeout=None) as ser:
            print(f"Connected to {usb_port} at {baud_rate} baud")

            # Thread for incoming data
            read_thread = threading.Thread(target=read_data, args=(ser,), daemon=True)
            read_thread.start()

            # Echo test
            echo_tests = [
                "",            
                "Testing 123",   
                "testing testing",        
                "!@#$"  
            ]

            for test in echo_tests:
                print(f"\nTesting echo with message: '{test}'")
                echo(ser, test)
                time.sleep(1)  # Allow time for echo response

    except serial.SerialException as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
