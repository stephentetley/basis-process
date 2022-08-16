/*
 * Copyright 2020 Stephen Tetley
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


namespace Basis/System {

    pub enum Process[r: Region](Interop/Lang.Process[r])
}


namespace Basis/System/Process {
    
    use Basis/Text.Charset;
    use Basis/Text.Charset.{Charset};

    use Basis/System.Process;
    use Basis/System.Process.{Process};
    use Basis/System.ProcessBuilder;
    use Basis/System.ProcessBuilder.{ProcessBuilder};


    pub def processBuilder(cmd: String, args: List[String]): ProcessBuilder[r, ka, Unit] \ Write(r) =
        Basis/System/ProcessBuilder.command!(cmd, args)


    pub def waitFor(p: Process[r]): Result[Int32, String] \ IO =
        use Result.flatMap;
        let Process(p1) = p;
        Interop/Lang/Process.waitFor!(p1)


    pub def getInput(cs: Charset, p: Process[r]): Result[String, String] \ IO =
        use Result.flatMap;
        let Process(p1) = p;
        let Charset(cs1) = cs;
        let strm    = Interop/Lang/Process.getInputStream(p1);
        let* bytes  = Interop/IO/InputStream.readAllBytes(strm);
        Ok(Interop/Lang/String.fromArrayWithCharset(cs1, bytes))


    pub def getError(cs: Charset, p: Process[r]): Result[String, String] \ IO =
        use Result.flatMap;
        let Process(p1) = p;
        let Charset(cs1) = cs;
        let strm    = Interop/Lang/Process.getErrorStream(p1);
        let* bytes  = Interop/IO/InputStream.readAllBytes(strm);
        Ok(Interop/Lang/String.fromArrayWithCharset(cs1, bytes))
        


    pub type alias ProcessArgs =
        { cmd :: String
        , args :: List[String]
        , charset :: Charset
        }

    /// Return with an Exit Code
    pub def processWithExitCode(args: ProcessArgs): Result[{exitCode :: Int32, processResponse :: String}, String] \ IO =
        use Result.flatMap;
        region r1 {
            let pb          = processBuilder(args.cmd, args.args);
            let* proc       = Basis/System/ProcessBuilder.start(r1, pb);
            let* respGood   = getInput(args.charset, proc);
            let* respBad    = getError(args.charset, proc);
            let* code       = waitFor(proc);
            Ok({exitCode = code, processResponse = if (code == 0) respGood else respBad})
        }


    pub def process(args: ProcessArgs): Result[{processResponse :: String}, String] \ IO =
        use Result.flatMap;
        region r1 {
            let pb          = processBuilder(args.cmd, args.args);
            let* proc       = Basis/System/ProcessBuilder.start(r1, pb);
            let* respGood   = getInput(args.charset, proc);
            let* respBad    = getError(args.charset, proc);
            let* code       = waitFor(proc);
            if (code == 0) 
                Ok({processResponse = respGood})
            else 
                Err(respBad)
        }


}
