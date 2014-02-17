------------------------------------------------------------------------
--  yc422.vhd
--  compute YC 422 from YCrCb input
--
--  latency : 2 clk
--
--  Copyright (C) 2014 M.FORET
--
--  This program is free software: you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation, either version
--  2 of the License, or (at your option) any later version.
------------------------------------------------------------------------

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Input :
-- lval  =  _|--------------------------------------------------------------- ...
-- YUV   =   | Y0U0V0 | Y1U1V1 | Y2U2V2 | Y3U3V3 | Y4U4V4 | Y5U5V5 | Y6U6V6 | ...
-- Output :
-- lval  =  ___________________|----------------------------------------------------
--  Y    =   |   X    |   X    |   Y0    |   Y1    |   Y2    |   Y3    |   Y4    | ...
--  C    =   |   X    |   X    |(U0+U1)/2|(V0+V1)/2|(U2+U3)/2|(V2+V3)/2|(U4+U5)/2| ...
--                                 Cb        Cr        Cb        Cr        Cb
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity yc422 is
  port(
      -- In -------------------------------------
      clk    : in  std_logic;
      fval   : in  std_logic;
      lval   : in  std_logic;
      dval   : in  std_logic;
      Y      : in  std_logic_vector(11 downto 0);
      Cb     : in  std_logic_vector(11 downto 0);  -- U
      Cr     : in  std_logic_vector(11 downto 0);  -- V
      -- Out -------------------------------------
      fval2  : out std_logic;
      lval2  : out std_logic;
      dval2  : out std_logic;
      Y_o    : out std_logic_vector(11 downto 0);
      C_o    : out std_logic_vector(11 downto 0)
    );
end yc422;


architecture rtl of yc422 is

signal fval1     : std_logic := '0';
signal lval1     : std_logic := '0';
signal dval1     : std_logic := '0';
--
signal r422      : std_logic := '0';
signal Y1        : std_logic_vector(Y'length-1 downto 0) := (others=>'0');
signal Y2        : std_logic_vector(Y'length-1 downto 0) := (others=>'0');
------
signal Cb1       : unsigned(Cb'length-1 downto 0) := (others=>'0');
signal Cr1       : unsigned(Cr'length-1 downto 0) := (others=>'0');
------
signal Cb_sum    : unsigned(Cb'length downto 0) := (others=>'0');
signal Cr_sum    : unsigned(Cr'length downto 0) := (others=>'0');
signal Cr_sum1   : unsigned(Cr'length downto 0) := (others=>'0');


begin

  -- sequence 422
  -- lval  =  _|------------------------------------------------------ ...
  -- YUV   =   | Y0U0V0 | Y1U1V1 | Y2U2V2 | Y3U3V3 | Y4U4V4 | Y5U5V5 | ...
  -- r422  =       0        1        0        1        0        1
  process(clk)
  begin
    if rising_edge(clk) then
        if (lval='0') then
            r422 <= '0';
        else
            r422 <= not(r422);
        end if;
    end if;
  end process;


  process(clk)
  begin
    if rising_edge(clk) then
        Y1 <= Y;
        Y2 <= Y1;
    end if;
  end process;


  process(clk)
  begin
    if rising_edge(clk) then
        fval1 <= fval;
        lval1 <= lval;
        dval1 <= dval;
    end if;
  end process;


  process(clk)
  begin
    if rising_edge(clk) then
        Cr1 <= unsigned(Cr);
        Cb1 <= unsigned(Cb);
    end if;
  end process;


-- compute sum of Cb & Cr
Cb_sum <= ("0" & Cb1) + unsigned(Cb);
Cr_sum <= ("0" & Cr1) + unsigned(Cr);

  process(clk)
  begin
    if rising_edge(clk) then
        Cr_sum1 <= Cr_sum;
    end if;
  end process;



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Outputs

Y_o <= Y2;

  process (clk)
  begin
    if rising_edge(clk) then
        if (fval1='0' or lval1='0') then
            C_o <= std_logic_vector(Cb1);
        elsif (r422='1') then
            C_o <= std_logic_vector(Cb_sum(Cb_sum'high downto 1));
        else
            C_o <= std_logic_vector(Cr_sum1(Cr_sum1'high downto 1));
        end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
        fval2 <= fval1;
        lval2 <= lval1;
        dval2 <= dval1;
    end if;
  end process;

end rtl;
