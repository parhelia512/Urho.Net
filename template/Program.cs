﻿using Urho;

namespace TEMPLATE_PROJECT_NAME
{
    class Program
    {
        static void Main(string[] args)
        {
#if _DESKTOP_PUBLISHED_BINARY_
            var applicationPath = System.IO.Path.GetDirectoryName(System.Diagnostics.Process.GetCurrentProcess().MainModule.FileName);
            System.IO.Directory.SetCurrentDirectory(applicationPath);
#endif          
            new TEMPLATE_CLASS_NAME().Run();
        }
    }
}

