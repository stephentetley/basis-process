/*
 * Copyright 2022 Stephen Tetley
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


namespace Interop/System {

    pub enum ProcessBuilder[r: Region, ka: Type, a: Type](MonadLib.Builder[r, ka, ##java.lang.ProcessBuilder, a])

    instance Functor[ProcessBuilder[r, ka]] {
        pub def map(f: a -> b & ef, ma: ProcessBuilder[r, ka, a]): ProcessBuilder[r, ka, b] & ef = 
            Interop/System/ProcessBuilder.map(f, ma)
    }

    instance Applicative[ProcessBuilder[r, ka]] {
        pub def point(x: a): ProcessBuilder[r, ka, a] =  
            Interop/System/ProcessBuilder.point(x)

        pub def ap(mf: ProcessBuilder[r, ka, a -> b & ef], ma: ProcessBuilder[r, ka, a]): ProcessBuilder[r, ka, b] & ef =
            Interop/System/ProcessBuilder.ap(mf, ma)
    }

    instance Monad[ProcessBuilder[r, ka]] {
        pub def flatMap(f: a -> ProcessBuilder[r, ka, b] & ef, ma: ProcessBuilder[r, ka, a]): ProcessBuilder[r, ka, b] & ef =
            Interop/System/ProcessBuilder.flatMap(f, ma)
    }

}


namespace Interop/System/ProcessBuilder {

    use Interop/System.ProcessBuilder;
    use Interop/System.ProcessBuilder.{ProcessBuilder};

    use Interop/System.FilePath;
    use Interop/System.FilePath.{FilePath};
    use Interop/System.Process;
    use Interop/System.Process.{Process};


    pub def getProcessBuilder(x: ProcessBuilder[r, ka, a]): MonadLib.Builder[r, ka, ##java.lang.ProcessBuilder, a] = 
        let ProcessBuilder(x1) = x;
        x1

    /// ///
    /// /// Returns the result of applying `ma` to the initial state `s`.
    /// ///
    /// def runBuilder(_: Region[r], ma: ProcessBuilder[r, a, a], 
    ///                 s: ##java.lang.ProcessBuilder): Result[a, String] & r =
    ///     let ProcessBuilder(f) = ma;
    ///     let cont = a -> Ok(a) as & r;
    ///     f(s, cont)


    pub def point(x: a): ProcessBuilder[r, ka, a] = ProcessBuilder(MonadLib/Builder.point(x))

    pub def map(f: a -> b & ef, ma: ProcessBuilder[r, ka, a]): ProcessBuilder[r, ka, b] & ef =
        ProcessBuilder(MonadLib/Builder.map(f, getProcessBuilder(ma)))

    pub def ap(mf: ProcessBuilder[r, ka, a -> b & ef], ma: ProcessBuilder[r, ka, a]): ProcessBuilder[r, ka, b] & ef =
        ProcessBuilder(MonadLib/Builder.ap(getProcessBuilder(mf), getProcessBuilder(ma)))


    pub def flatMap(f: a -> ProcessBuilder[r, ka, b] & ef, ma: ProcessBuilder[r, ka, a]): ProcessBuilder[r, ka, b] & ef =
        ProcessBuilder(MonadLib/Builder.flatMap(f >> getProcessBuilder, getProcessBuilder(ma)))

    pub def throwError(msg: String): ProcessBuilder[r, ka, a] =
        ProcessBuilder(MonadLib/Builder.throwError(msg))

    pub def liftSetter(f: ##java.lang.ProcessBuilder -> ##java.lang.ProcessBuilder & ef): ProcessBuilder[r, ka, Unit] & ef =
        ProcessBuilder(MonadLib/Builder.liftSetter(f))

    pub def liftGetter(f: ##java.lang.ProcessBuilder -> a & ef): ProcessBuilder[r, ka, a] & ef =
        ProcessBuilder(MonadLib/Builder.liftGetter(f))

    ///
    /// Returns the result of applying `ma` to the initial state `s`.
    ///
    def runBuilder(r: Region[r], 
                        ma: ProcessBuilder[r, a, a], 
                        s: ##java.lang.ProcessBuilder): Result[a, String] & r = 
        MonadLib/Builder.runBuilder(r, getProcessBuilder(ma), s)

    /// Must be Impure uses IO...
    pub def start(r: Region[r], ma: ProcessBuilder[r, a, a]): Result[Process, String] \ { Write(r), Impure } = 
        import new java.lang.ProcessBuilder(##java.util.List): ##java.lang.ProcessBuilder & r as newProcessBuilder;
        import java.lang.ProcessBuilder.start(): ##java.lang.Process & Impure as start1;
        try {
            let strs = Interop/Collections/RawList.fromListViaArrayList(() as Region[r], Nil: List[String]);
            let jbuilder = newProcessBuilder(Interop/Collections/RawList.getRawList(strs));
            match runBuilder(r, ma, jbuilder) {
                case Err(msg) => Err(msg)
                case Ok(_)    => Ok(Process(start1(jbuilder)))
            }
        } catch {
            case ex: ##java.lang.Exception => 
                import java.lang.Throwable.getMessage(): String & r;
                Err(getMessage(ex))
        }


    /// API...


    pub def command!(cmd: String, args: List[String]): ProcessBuilder[r, ka, Unit] \ Write(r) =
        import java.lang.ProcessBuilder.command(##java.util.List): ##java.lang.ProcessBuilder & r;
        let strs = Interop/Collections/RawList.fromListViaArrayList(() as Region[r], cmd :: args);
        liftSetter(pb -> command(pb, Interop/Collections/RawList.getRawList(strs)))


    pub def setDirectory!(p: FilePath): ProcessBuilder[r, ka, Unit] \ Write(r) = 
        import java.lang.ProcessBuilder.directory(##java.io.File): ##java.lang.ProcessBuilder & r;
        import new java.io.File(String): ##java.io.File & r as newFile;
        let fn = pb -> {
            let filename = ToString.toString(p);
            let file1 = newFile(filename);
            directory(pb, file1)
        };
        liftSetter(fn)

    pub def getDirectory(): ProcessBuilder[r, ka, FilePath] \ Write(r) = 
        import java.lang.ProcessBuilder.directory(): ##java.io.File & r;
        import java.io.File.toPath(): ##java.nio.file.Path & r;
        liftGetter(pb -> directory(pb) |> toPath |> FilePath)

}
