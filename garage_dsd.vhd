LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY garage_dsd IS
    PORT (
        sensor_in, sensor_out, openbutton, clk: IN STD_LOGIC;
        lightSensor: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        leds: OUT STD_LOGIC_VECTOR(1 TO 7);
        lamp: OUT STD_LOGIC;
        pwm: OUT STD_LOGIC
    );
END garage_dsd;

ARCHITECTURE arch OF garage_dsd IS
    SIGNAL c: INTEGER := 0;
    SIGNAL sensor_in_prevState: STD_LOGIC := '1';
    SIGNAL sensor_out_prevState: STD_LOGIC := '1';
    SIGNAL openbutton_prevState: STD_LOGIC := '1';
    SIGNAL freqCount: INTEGER := 2000000;
    SIGNAL startCount: INTEGER := 0;
    -- motor --
    CONSTANT clk_hz: REAL := 10.0e6; -- 10 megahertz 
    CONSTANT pulse_hz: REAL := 50.0; -- PWM pulse frequency
    CONSTANT min_pulse_us: REAL := 500.0; -- uS pulse width at min position
    CONSTANT max_pulse_us: REAL := 2500.0; -- uS pulse width at max position
    CONSTANT step_count: POSITIVE := 2**8; -- 256 positions for 180 degrees, so 127 for 90 degrees and 0 for 0 degrees
    SIGNAL position: INTEGER RANGE 0 TO step_count - 1;
    SIGNAL motor_ctrl: STD_LOGIC := '0'; -- when 1 motor moves, when 0 motor doesn't move
    -- end motor --
BEGIN
    PROCESS(clk)
    BEGIN
        IF clk'EVENT AND clk = '1' THEN
            IF lightSensor >= 150 THEN
                lamp <= '1';
            ELSE
                lamp <= '0';
            END IF;

            IF openbutton_prevState /= openbutton THEN
                IF openbutton = '1' THEN
                    IF c /= 4 THEN
                        motor_ctrl <= '1';
                    END IF;
                    openbutton_prevState <= '1';
                ELSE
                    openbutton_prevState <= '0';
                END IF;
            END IF;

            IF motor_ctrl = '1' THEN
                position <= 127;
            END IF;

            startCount <= startCount + 1;
            IF startCount = freqCount THEN
                startCount <= 0;
                IF sensor_in_prevState /= sensor_in THEN
                    IF sensor_in = '1' THEN
                        IF c = 4 THEN
                            c <= 4;
                        ELSE
                            c <= c + 1;
                        END IF;
                        motor_ctrl <= '0';
                        position <= 0;
                        sensor_in_prevState <= '1';
                    ELSE
                        sensor_in_prevState <= '0';
                    END IF;
                END IF;

                IF startCount = freqCount THEN
                    startCount <= 0;
                    IF sensor_out_prevState /= sensor_out THEN
                        IF sensor_out = '1' THEN
                            IF c = 0 THEN
                                c <= 0;
                            ELSE
                                c <= c - 1;
                            END IF;
                            sensor_out_prevState <= '1';
                        ELSE
                            sensor_out_prevState <= '0';
                        END IF;
                    END IF;
                END IF;
            END IF;

            CASE c IS
                WHEN 0 =>
                    leds <= "0000001";
                WHEN 1 =>
                    leds <= "1001111";
                WHEN 2 =>
                    leds <= "0010010";
                WHEN 3 =>
                    leds <= "0000110";
                WHEN 4 =>
                    leds <= "1001100";
                WHEN 5 =>
                    leds <= "0100100";
                WHEN 6 =>
                    leds <= "0100000";
                WHEN 7 =>
                    leds <= "0001111";
                WHEN 8 =>
                    leds <= "0000000";
                WHEN 9 =>
                    leds <= "0000100";
                WHEN OTHERS =>
                    leds <= "1111111";
            END CASE;
        END IF;
    END PROCESS;

    StageServo: ENTITY work.servo(rt1)
    GENERIC MAP (
        clk_hz, pulse_hz, min_pulse_us, max_pulse_us, step_count
    )
    PORT MAP (
        clk, '0', position, pwm
    );
END arch;