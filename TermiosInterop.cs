using System;
using System.Runtime.InteropServices;

namespace Cspotcode {

    public class TermiosInterop {
        [StructLayout(LayoutKind.Explicit, Size = 32)]
        public struct Termios {
            // [FieldOffset(0)]
            // public uint c_iflag;           /* input mode flags */
            // [FieldOffset(8)]
            // public uint c_oflag;           /* output mode flags */
            // [FieldOffset(16)]
            // public uint c_cflag;           /* control mode flags */
            // [FieldOffset(24)]
            // public uint c_lflag;           /* local mode flags */

            // [FieldOffset(0)]
            // public fixed byte c_arr[32];

            [FieldOffset(0)]
            public byte c_0;
            [FieldOffset(1)]
            public byte c_1;
            [FieldOffset(2)]
            public byte c_2;
            [FieldOffset(3)]
            public byte c_3;
            [FieldOffset(4)]
            public byte c_4;
            [FieldOffset(5)]
            public byte c_5;
            [FieldOffset(6)]
            public byte c_6;
            [FieldOffset(7)]
            public byte c_7;
            [FieldOffset(8)]
            public byte c_8;
            [FieldOffset(9)]
            public byte c_9;
            [FieldOffset(10)]
            public byte c_10;
            [FieldOffset(11)]
            public byte c_11;
            [FieldOffset(12)]
            public byte c_12;
            [FieldOffset(13)]
            public byte c_13;
            [FieldOffset(14)]
            public byte c_14;
            [FieldOffset(15)]
            public byte c_15;
            [FieldOffset(16)]
            public byte c_16;
            [FieldOffset(17)]
            public byte c_17;
            [FieldOffset(18)]
            public byte c_18;
            [FieldOffset(19)]
            public byte c_19;
            [FieldOffset(20)]
            public byte c_20;
            [FieldOffset(21)]
            public byte c_21;
            [FieldOffset(22)]
            public byte c_22;
            [FieldOffset(23)]
            public byte c_23;
            [FieldOffset(24)]
            public byte c_24;
            [FieldOffset(25)]
            public byte c_25;
            [FieldOffset(26)]
            public byte c_26;
            [FieldOffset(27)]
            public byte c_27;
            [FieldOffset(28)]
            public byte c_28;
            [FieldOffset(29)]
            public byte c_29;
            [FieldOffset(30)]
            public byte c_30;
            [FieldOffset(31)]
            public byte c_31;
        }

        public static void BlitTermiosToIntPtr(Termios termios, IntPtr intPtr) {
            unsafe {
                ((Termios*)intPtr.ToPointer())[0] = termios;
            }
        }
        public static void BlitIntPtrToTermios(IntPtr intPtr, ref Termios termios) {
            unsafe {
                termios = ((Termios*)intPtr.ToPointer())[0];
            }
        }

        [DllImport("libc")]
        public static extern int tcgetattr(
            int fd,
            IntPtr termios_p
        );

        [DllImport("libc")]
        public static extern int tcsetattr(
            int fd,
            int optional_actions,
            IntPtr termios_p
        );
    }
}
