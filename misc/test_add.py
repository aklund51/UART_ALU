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
    lsb_len = packet_len & 0xFF
    msb_len = (packet_len >> 8) & 0xFF

    # Combine all into packet
    packet = bytearray([opcode, RESERVED, lsb_len, msb_len]) + data
    return packet


def convert_to_bytes(number):
    """Convert 32-bit integer to 4 bytes in big-endian format"""
    return (number & 0xFFFFFFFF).to_bytes(4, byteorder='big', signed=False)


#def add32(operands):   



# Main function
def main():
    usb_port = '/dev/ttyUSB1'  # Replace with your port
    baud_rate = 9600
    
    try:
        # Initialize serial connection
        with serial.Serial(usb_port, baud_rate, timeout=None) as ser:
            print(f"Connected to {usb_port} at {baud_rate} baud")

             # Thread for incoming data
            read_thread = threading.Thread(target=read_data, args=(ser,), daemon=True)
            read_thread.start()

    except serial.SerialException as e:
        print(f"Error opening {usb_port}: {e}")


if __name__ == "__main__":
    main()

