# Load Windows Forms assembly
[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

$scriptDirectory = $PWD.Path

# URLs for the remote files
$pngUrl = "https://valentine-1a3r.onrender.com/hutch.png"
$wavUrl = "https://valentine-1a3r.onrender.com/whistle.wav"

# Local paths for the downloaded files
$pngFile = "$scriptDirectory\hutch.png"
$wavFile = "$scriptDirectory\whistle.wav"

# Function to download files
function Download-File($url, $outputPath) {
    Write-Host "Downloading $url..."
    Invoke-WebRequest -Uri $url -OutFile $outputPath
    Write-Host "Downloaded $outputPath."
}

# Download the .png and .wav files
Download-File $pngUrl $pngFile
Download-File $wavUrl $wavFile

function Initialize-Form {
    Write-Host "Initializing form..."
    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.BackColor = [System.Drawing.Color]::Black  # Set background color to black
    $form.TransparencyKey = $form.BackColor
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $form.TopMost = $true

    # Get the size of the primary screen
    $screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    $screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

    $pictureBox = New-Object System.Windows.Forms.PictureBox
    $pictureBox.Image = [System.Drawing.Image]::FromFile($pngFile)

    # Resize the image to fit the screen
    $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage

    $pictureBox.BackColor = $form.BackColor
    $pictureBox.Dock = [System.Windows.Forms.DockStyle]::Fill
    $pictureBox.Enabled = $true

    $form.Controls.Add($pictureBox)

    return $form
}

function ShowImageAndPlaySound {
    Write-Host "Playing sound and showing image..."
    # Play audio
    $mediaPlayer = New-Object System.Media.SoundPlayer
    $mediaPlayer.SoundLocation = $wavFile
    $mediaPlayer.Play()

    Write-Host "Sound played."

    # Wait for a short duration before showing the form
    Start-Sleep -Milliseconds 500
    Write-Host "Waited for 500 milliseconds."

    $form = Initialize-Form
    $form.Show()
    $form.Refresh()

    Write-Host "Form shown."

    # Wait for 7.253 seconds
    Start-Sleep -Milliseconds 7253
    Write-Host "Waited for 7253 milliseconds."

    # Close the form
    $form.Close()
    Write-Host "Form closed."
}

$CSharpCode = @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class UserInputCapture {
    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    private static bool isDebouncing = false;
    private const int debounceCooldownMilliseconds = 500;  // Set the cooldown period (in milliseconds)

    public static void CaptureUserInput(Action showImageAndPlaySound) {
        Console.WriteLine("Capturing user input. Press Enter to exit...");
        char[] sequence = new char[3];  // Array to store the last three pressed keys
        int index = 0;  // Index to keep track of the last pressed key
        while (true) {
            if (Console.KeyAvailable && Console.ReadKey(true).Key == ConsoleKey.Enter) {
                Console.WriteLine("Enter key pressed. Exiting...");
                break;
            }
            if (IsAnyKeyPressed()){
                char keyPressed = GetKeyPressed();
                sequence[index] = keyPressed;
                index = (index + 1) % 3;  // Update index circularly
            
                // Debug statements to check the sequence
                Console.WriteLine("Sequence: " + sequence[0] + sequence[1] + sequence[2]);
            
                // Check if the sequence is "sql"
                if ((sequence[0] == 'S' && sequence[1] == 'Q' && sequence[2] == 'L') || 
                (sequence[0] == 'Q' && sequence[1] == 'L' && sequence[2] == 'S') || 
                (sequence[0] == 'L' && sequence[1] == 'S' && sequence[2] == 'Q')) {
                    Console.WriteLine("Keyword 'sql' detected. Exiting...");
                    break;
                }
            }         
            if (!isDebouncing && IsAnyKeyPressed()) {
                Console.WriteLine("Input detected!");
                isDebouncing = true;
                ThreadPool.QueueUserWorkItem(state => {
                    while (IsAnyKeyPressed()) {
                        Thread.Sleep(5);
                    }
                    isDebouncing = false;
                });
                Console.WriteLine("Calling ShowImageAndPlaySound function...");
                showImageAndPlaySound();  // Call the function passed as parameter
            }
            System.Threading.Thread.Sleep(5);  // Adjust the sleep time as needed
        }
    }

    private static bool IsAnyKeyPressed() {
        for (int i = 1; i < 256; i++) {
            if ((GetAsyncKeyState(i) & 0x8000) != 0) {
                return true;
            }
        }
        return false;
    }

    private static char GetKeyPressed() {
        for (int i = 8; i < 256; i++) {
            short state = GetAsyncKeyState(i);
            if ((state & 0x8000) != 0) {
                return (char)i;  // Return the pressed key
            }
        }
        return '\0';  // Return null character if no key is pressed
    }
}
"@

Add-Type -TypeDefinition $CSharpCode

try {
    [UserInputCapture]::CaptureUserInput({ ShowImageAndPlaySound })
} catch {
    Write-Host "Error: $_"
}
