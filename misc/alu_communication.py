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
    """Create a packet with an opcode and data."""
    packet_len = len(data) + 4
    lsb_len = packet_len & 0xFF
    msb_len = (packet_len >> 8) & 0xFF
    return bytearray([opcode, RESERVED, lsb_len, msb_len]) + data

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
    """Prepare a packet for the echo function."""
    data = message.encode('utf-8')  # Convert to bytes
    return create_packet(ECHO_OPCODE, data)

def receive_result(ser):
    """Receive a 32-bit result from the serial port."""
    result_bytes = ser.read(4)  # Ensure exactly 4 bytes are read
    if len(result_bytes) < 4:
        print(f"Error: Expected 4 bytes, received {len(result_bytes)} bytes")
        return None
    return struct.unpack('>i', result_bytes)[0]  # Interpret as signed 32-bit integer

def main():
    usb_port = '/dev/cu.usbserial-ib0RDpMt1'  # Replace with your USB port
    baud_rate = 9600

    try:
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

                    expected_result = sum(x & 0xFFFFFFFF for x in operands) & 0xFFFFFFFF  # 32-bit mask
                    packet = add32(operands)
                    ser.write(packet)
                    
                    print(f"Sent packet: {packet.hex()}") 
                    result = receive_result(ser)

                    if result is not None:
                        print(f"Expected: {expected_result} (0x{expected_result:08X})")
                        print(f"Received: {result} (0x{result:08X})")
                        print("✅ Result matches expected" if result == expected_result else "❌ Result does NOT match expected")

                elif choice == "2":
                    operands = input("Enter integers to multiply (separated by spaces): ").strip()
                    operands = list(map(int, operands.split()))

                    expected_result = 1
                    for num in operands:
                        expected_result = (expected_result * num) & 0xFFFFFFFF  # 32-bit mask

                    packet = mul32(operands)
                    ser.write(packet)

                    print(f"Sent packet: {packet.hex()}") 
                    result = receive_result(ser)

                    if result is not None:
                        print(f"Expected: {expected_result} (0x{expected_result:08X})")
                        print(f"Received: {result} (0x{result:08X})")
                        print("✅ Result matches expected" if result == expected_result else "❌ Result does NOT match expected")

                elif choice == "3":
                    numerator = int(input("Enter the numerator: ").strip())
                    denominator = int(input("Enter the denominator: ").strip())

                    if denominator == 0:
                        print("❌ Error: Division by zero is not allowed.")
                        continue

                    expected_result = numerator // denominator  # Integer division

                    packet = div32(numerator, denominator)
                    ser.write(packet)

                    print(f"Sent packet: {packet.hex()}") 
                    result = receive_result(ser)

                    if result is not None:
                        print(f"Expected: {expected_result} (0x{expected_result:08X})")
                        print(f"Received: {result} (0x{result:08X})")
                        print("✅ Result matches expected" if result == expected_result else "❌ Result does NOT match expected")

                elif choice == "4":
                    message = input("Enter message to send: ").strip()
                    packet = echo(message)
                    ser.write(packet)

                    print(f"Sent packet: {packet.hex()}") 
                    result = ser.read(len(packet))  # Read the expected echoed message

                    print(f"Echoed: {result.decode('utf-8', errors='ignore')}")

                elif choice == "5":
                    print("Exiting...")
                    break

                else:
                    print("❌ Invalid choice. Please try again.")

    except serial.SerialException as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
