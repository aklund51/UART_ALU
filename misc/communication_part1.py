import serial

def main():
    # Specify the USB port and baud rate
    usb_port = "/dev/tty.usbserial-ib0RDpMt0"  # Change this to your USB device path
    baud_rate = 9600  # Adjust this to match your device's configuration

    try:
        # Open the serial connection
        with serial.Serial(usb_port, baud_rate, timeout=None) as ser:
            print(f"Connected to {usb_port} at {baud_rate} baud")

            while True:
                # Get user input (1 character)
                user_input = input("Enter a single character (or 'exit' to quit): ")

                if user_input.lower() == 'exit':
                    print("Exiting the program.")
                    break

                if len(user_input) != 1:
                    print("Please enter only one character.")
                    continue

                # Send the character to the USB device
                ser.write(user_input.encode('utf-8'))

                # Wait for and read the response from the device
                response = ser.readline().decode('utf-8').strip()
                
                if response:
                    print(f"Response from device: {response}")
                else:
                    print("No response from device.")

    except serial.SerialException as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
