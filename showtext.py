import subprocess
import shutil

class ComfyUIBashExecutor:
    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                # The text input will now be treated as the bash command
                "command": ("STRING", {"forceInput": True}),
            },
            "hidden": {
                "unique_id": "UNIQUE_ID",
                "extra_pnginfo": "EXTRA_PNGINFO",
            },
        }

    INPUT_IS_LIST = True
    RETURN_TYPES = ("STRING",)
    FUNCTION = "execute_bash"
    OUTPUT_NODE = True
    OUTPUT_IS_LIST = (True,)

    CATEGORY = "utils"

    def execute_bash(self, command, unique_id=None, extra_pnginfo=None):
        # Since INPUT_IS_LIST = True, 'command' is passed as a list. 
        # We join them together into a single string command.
        full_command = " ".join(command)
        
        # Security/OS Check: Ensure bash is actually available
        shell_executable = shutil.which("bash") or shutil.which("sh")
        
        if not shell_executable:
            output_text = "Error: No Bash-compatible shell found on this system."
        else:
            try:
                # Runs the command through bash, captures output, and prevents hanging
                result = subprocess.run(
                    full_command,
                    shell=True,
                    executable=shell_executable,
                    text=True,
                    capture_output=True,
                    timeout=60 # Safety timeout in seconds
                )
                
                # Combine stdout and stderr so you see everything that happened
                output_text = result.stdout
                if result.stderr:
                    output_text += f"\n[STDERR]:\n{result.stderr}"
                    
            except subprocess.TimeoutExpired:
                output_text = "Error: Command timed out after 60 seconds."
            except Exception as e:
                output_text = f"Error executing command: {str(e)}"

        # Update the UI node widget text dynamically (kept from your original code)
        if unique_id is not None and extra_pnginfo is not None:
            if isinstance(extra_pnginfo, list) and len(extra_pnginfo) > 0:
                if isinstance(extra_pnginfo[0], dict) and "workflow" in extra_pnginfo[0]:
                    workflow = extra_pnginfo[0]["workflow"]
                    node = next(
                        (x for x in workflow["nodes"] if str(x["id"]) == str(unique_id[0])),
                        None,
                    )
                    if node:
                        node["widgets_values"] = [output_text]

        # Return the output to the UI and as a pass-through string for other nodes
        return {"ui": {"text": [output_text]}, "result": ([output_text],)}


NODE_CLASS_MAPPINGS = {
    "BashExecutor": ComfyUIBashExecutor,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "BashExecutor": "Execute Bash Command",
}
