#include <windows.h>
#include <string>
#include <sstream>
#include <vector>
#include <algorithm>
#include <iostream> // Added for std::cerr

//const std::string exePath = "C:\\Programs\\ConsoleGetArgs\\VpnShim.exe";
//const std::string exePath = "C:\\Programs\\ConsoleGetArgs\\ShowArgs.exe";
//const std::string exePath = "C:\\Programs\\ConsoleGetArgs\\ShowArgs-NoValidation.exe";
//const std::string exePath = "C:\\Programs\\ConsoleGetArgs\\ShowArgs-Test.exe";
const std::string exePath = "C:\\Program Files (x86)\\ExpressVPN\\services\\ExpressVPN.CLI.exe";

#define RUN_AS_ADMIN
//#define TEST_MODE_DISPLAY_ARGS_NOEXEC 
#define PROTOCOL_ID "vpn://"

// Helper function to split a string into tokens by a delimiter
std::vector<std::string> split(const std::string& str, char delimiter) {
    std::vector<std::string> tokens;
    std::stringstream ss(str);
    std::string token;
    while (std::getline(ss, token, delimiter)) {
        tokens.push_back(token);
    }
    return tokens;
}

// Function to process a single argument string
std::vector<std::string> process_command(const std::string& input) {
    const std::string protocol = PROTOCOL_ID;
    std::vector<std::string> result;

    // Check if the input starts with the expected protocol
    if (input.rfind(protocol, 0) == 0) {
        // Remove the protocol part
        std::string commandPart = input.substr(protocol.length());

        // Replace '+' with space to split later
        std::replace(commandPart.begin(), commandPart.end(), '+', ' ');

        // Replace '/' with space to split later
        std::replace(commandPart.begin(), commandPart.end(), '/', ' ');

        // Split the processed command part by space
        result = split(commandPart, ' ');
    }
    else {
        result.push_back("Invalid protocol!");
    }

    return result;
}

// Function to process all arguments and return a vector of processed strings
std::vector<std::string> process_arguments(int argc, char* argv[]) {
    std::vector<std::string> processedArgs;

    for (int i = 1; i < argc; ++i) {
        // Process each argument and append all resulting parts to processedArgs
        std::vector<std::string> parts = process_command(argv[i]);
        processedArgs.insert(processedArgs.end(), parts.begin(), parts.end());
    }

    return processedArgs;
}

// Helper function to convert std::string to std::wstring
std::wstring string_to_wstring(const std::string& str) {
    return std::wstring(str.begin(), str.end());
}

bool execute_as_user(const std::string& exePath, const std::vector<std::string>& arguments) {
    // Construct the command line with arguments
    std::stringstream cmdLine;
    cmdLine << "\"" << exePath << "\"";
    for (const auto& arg : arguments) {
        cmdLine << " \"" << arg << "\"";
    }

    // Convert to wide strings for CreateProcessW
    std::wstring wideCmdLine = string_to_wstring(cmdLine.str());

    // Setup process startup information and process information structures
    STARTUPINFO si = { 0 };
    PROCESS_INFORMATION pi = { 0 };
    si.cb = sizeof(si);

    // Create the process
    if (!CreateProcessW(
        NULL,                              // Application name
        &wideCmdLine[0],                   // Command line
        NULL,                              // Process attributes
        NULL,                              // Thread attributes
        FALSE,                             // Inherit handles
        0,                                 // Creation flags
        NULL,                              // Environment
        NULL,                              // Current directory
        &si,                               // Startup info
        &pi                                // Process information
    )) {
        // Print error message
        std::cerr << "Failed to execute command as user: Error " << GetLastError() << std::endl;
        return false;
    }

    // Wait for the process to complete
    WaitForSingleObject(pi.hProcess, INFINITE);

    // Close handles
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    return true;
}


// Function to execute a command as administrator
bool execute_as_admin(const std::string& exePath, const std::vector<std::string>& arguments) {
    // Construct the command line with arguments
    //bool first = true;
    std::stringstream cmdLine;
    //cmdLine << "\"" << exePath << "\"";
    for (const auto& arg : arguments) {
        cmdLine << " \"" << arg << "\"";
    }

    // Convert to wide strings for ShellExecuteW
    std::wstring wideExePath = string_to_wstring(exePath);
    std::wstring wideCmdLine = string_to_wstring(cmdLine.str());

    // Execute as administrator
    HINSTANCE hInstance = ShellExecuteW(NULL, L"runas", wideExePath.c_str(), wideCmdLine.c_str(), NULL, SW_SHOW);
    return reinterpret_cast<int>(hInstance) > 32; // Return true if successful
}

int main(int argc, char* argv[]) {
    std::stringstream ss;
    std::stringstream sstitle;
    sstitle << argv[0] << " - Processed Arguments";

#ifdef TEST_MODE_DISPLAY_ARGS_NOEXEC
    if (argc > 1) {
        // Call process_arguments to handle all arguments
        std::vector<std::string> processedArgs = process_arguments(argc, argv);

        ss << "Processed Arguments:\n\n";
        for (size_t i = 0; i < processedArgs.size(); ++i) {
            ss << (i + 1) << ") " << processedArgs[i] << "\n";
        }
        std::string params = ss.str();
        std::string paramstitle = sstitle.str();
        // Display the processed arguments in a message box
        MessageBoxA(NULL, params.c_str(), paramstitle.c_str(), MB_OK | MB_ICONINFORMATION);
    }
    else {
        ss << "No parameters!";

        std::string params = ss.str();
        std::string paramstitle = sstitle.str();
        // Display the processed arguments in a message box
        MessageBoxA(NULL, params.c_str(), paramstitle.c_str(), MB_OK | MB_ICONINFORMATION);
    }
#else
    if (argc > 1) {
        // Call process_arguments to handle all arguments
        std::vector<std::string> processedArgs = process_arguments(argc, argv);

#ifdef RUN_AS_ADMIN
        if (!execute_as_admin(exePath, processedArgs)) {
#else 
        if (!execute_as_user(exePath, processedArgs)) {
#endif
            MessageBoxA(NULL, "Failed to execute the command as administrator.", "Error", MB_OK | MB_ICONERROR);
        }
    }
#endif

    return 0;
}
