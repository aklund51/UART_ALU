import serial
import time
import struct

# CONSTANTS
RESERVED = 0x00
ADD_OPCODE = 0x01
MUL_OPCODE = 0x02
DIV_OPCODE = 0x03
ECHO_OPCODE = 0xEC

def create_packet(opcode, data):
    packet_len = len(data) + 4
    lsb_len = packet_len & 0xFF
    msb_len = (packet_len >> 8) & 0xFF

    # Combine all into packet
    packet = bytearray([opcode, RESERVED, lsb_len, msb_len]) + data
    return packet

def add32(operands):
    """Prepare a packet to add a list of 32-bit integers."""
    data = b''.join(struct.pack('>I', x & 0xFFFFFFFF) for x in operands)
    return create_packet(ADD_OPCODE, data)

def mul32(operands):
    """Prepare a packet to multiply a list of 32-bit signed integers."""
    data = b''.join(struct.pack('>i', x) for x in operands)
    return create_packet(MUL_OPCODE, data)

def div32(numerator, denominator):
    """Prepare a packet to divide two 32-bit signed integers."""
    data = struct.pack('>ii', numerator, denominator)
    return create_packet(DIV_OPCODE, data)

def echo(message):
    data = message.encode('utf-8')  # Convert to bytes
    return create_packet(ECHO_OPCODE, data)


def receive_result(ser, packet):
    """Receive a 32-bit result from the serial port."""
    result_bytes = ser.read(len(packet))
    # result = struct.unpack('>i', result_bytes)[0]  # Use signed int for generality
    return result_bytes

def main():
    usb_port = '/dev/cu.usbserial-ib0RDpMt1'  # Replace with your USB port
    baud_rate = 9600

    try:
        # Initialize serial connection
        with serial.Serial(port=usb_port, baudrate=baud_rate, timeout=1) as ser:
            print(f"Connected to {usb_port} at {baud_rate} baud")

            while True:
                print("\nChoose an operation:")
                print("1. Add 32-bit integers")
                print("2. Multiply 32-bit integers")
                print("3. Divide two 32-bit integers")
                print("4. Echo")
                print("5. Exit")

                choice = input("Enter your choice (1-5): ").strip()

                if choice == "1":
                    operands = input("Enter integers to add (separated by spaces): ").strip()
                    operands = list(map(int, operands.split()))
                    packet = add32(operands)
                    ser.write(packet)
                    print(f"Sent packet: {packet.hex()}") 
                    result = receive_result(ser, packet)
                    print(f"Result: {result}")

                elif choice == "2":
                    operands = input("Enter integers to multiply (separated by spaces): ").strip()
                    operands = list(map(int, operands.split()))
                    packet = mul32(operands)
                    ser.write(packet)
                    print(f"Sent packet: {packet.hex()}") 
                    result = receive_result(ser, packet)
                    print(f"Result: {result.hex}")

                elif choice == "3":
                    numerator = int(input("Enter the numerator: ").strip())
                    denominator = int(input("Enter the denominator: ").strip())
                    packet = div32(numerator, denominator)
                    ser.write(packet)
                    print(f"Sent packet: {packet.hex()}") 
                    result = receive_result(ser, packet)
                    print(f"Result: {result.hex}")

                elif choice == "4":
                    message = input("Enter message to send: \n")
                    packet = echo(message)
                    ser.write(packet)
                    print(f"Sent packet: {packet.hex()}") 
                    result = ser.read(len(packet))
                    print(f"Result: {result}")

                elif choice == "5":
                    print("Exiting...")
                    break

                else:
                    print("Invalid choice. Please try again.")

    except serial.SerialException as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
