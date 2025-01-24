import serial
import time
import threading

# CONSTANTS
RESERVED = 0x00
ADD_OPCODE = 0x01
MUL_OPCODE = 0x02
DIV_OPCODE = 0x03

def create_packet(opcode, data):
    packet_len = len(data) + 4
    header = bytes([opcode, RESERVED, packet_len & 0xFF, packet_len >> 8])

    # Combine all into packet
    return header + data

def add32(operands: list) -> bytes:
    num = b''.join((x & 0xFFFFFFFF).to_bytes(4, byteorder='big', signed=False) for x in operands)
    return create_packet(ADD_OPCODE, num)

def receive_result(ser):
    result_bytes = ser.read(4)
    result = int.from_bytes(result_bytes, byteorder='big', signed=False)
    return result

# Main function
def main():
    usb_port = '/dev/cu.usbserial-ib0RDpMt1'  # Replace with your port
    baud_rate = 9600
    
    try:
        # Initialize serial connection
        with serial.Serial(port=usb_port, baudrate=baud_rate, timeout=None) as ser:
            print(f"Connected to {usb_port} at {baud_rate} baud")

             # Example operands for addition
            add_cases = [
                [5, 10]         
                ]  # Example operands for 5 + 10
            for test in add_cases:
                add_packet = add32(test)

                expected = sum(x & 0xFFFFFFFF for x in test) & 0xFFFFFFFF

                print(f"\nCase:", [f'{x}' for x in test])
                print(f"Expected: {expected}")

                ser.write(add_packet)
                res = receive_result(ser)
                print(f"Received: {res}")

                if (res == expected):
                    print("Result matches expected")
                else:
                    print("Result does NOT match expected")

                time.sleep(0.2)

    except serial.SerialException as e:
        print(f"Error opening {usb_port}: {e}")


if __name__ == "__main__":
    main()

