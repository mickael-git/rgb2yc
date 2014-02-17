------------------------------------------------------------------------
--  RGB2YCrCb.vhd
--
--  latency : 3 clk
--
--  Copyright (C) 2014 M.FORET
--
--  This program is free software: you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation, either version
--  2 of the License, or (at your option) any later version.
------------------------------------------------------------------------

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Components YCrCb (10b) limited scale from RGB (10b) full scale
-- Y709 =  0.183R + 0.614G + 0.062B + 64
-- Cb   = -0.101R - 0.338G + 0.439B + 512
-- Cr   =  0.439R - 0.399G - 0.040B + 512
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity RGB2YCrCb is
    port(
      -- In -------------------------------------
      clk      : in  std_logic;
      fval     : in  std_logic;
      lval     : in  std_logic;
      dval     : in  std_logic;
      R        : in  std_logic_vector(11 downto 0);
      G        : in  std_logic_vector(11 downto 0);
      B        : in  std_logic_vector(11 downto 0);
      --
      bypass   : in  std_logic;
      -- Out -------------------------------------
      fval3    : out std_logic;
      lval3    : out std_logic;
      dval3    : out std_logic;
      Y_o      : out std_logic_vector(11 downto 0);
      Cb_o     : out std_logic_vector(11 downto 0);
      Cr_o     : out std_logic_vector(11 downto 0)
    );
end RGB2YCrCb;


architecture rtl of RGB2YCrCb is

constant NB_BIT_COEFF  : positive := 14;
constant VAL_NB_BIT    : real := real(2**NB_BIT_COEFF);

-- compute approximative value of constants
constant coeff_R_Y709  : unsigned(NB_BIT_COEFF-1 downto 0) := to_unsigned(integer(0.183*VAL_NB_BIT+0.5), NB_BIT_COEFF);
constant coeff_R_Cr    : unsigned(NB_BIT_COEFF-1 downto 0) := to_unsigned(integer(0.439*VAL_NB_BIT+0.5), NB_BIT_COEFF);
constant coeff_R_Cb    : unsigned(NB_BIT_COEFF-1 downto 0) := to_unsigned(integer(0.101*VAL_NB_BIT+0.5), NB_BIT_COEFF);
constant coeff_G_Y709  : unsigned(NB_BIT_COEFF-1 downto 0) := to_unsigned(integer(0.614*VAL_NB_BIT+0.5), NB_BIT_COEFF);
constant coeff_G_Cr    : unsigned(NB_BIT_COEFF-1 downto 0) := to_unsigned(integer(0.399*VAL_NB_BIT+0.5), NB_BIT_COEFF);
constant coeff_G_Cb    : unsigned(NB_BIT_COEFF-1 downto 0) := to_unsigned(integer(0.338*VAL_NB_BIT+0.5), NB_BIT_COEFF);
constant coeff_B_Y709  : unsigned(NB_BIT_COEFF-1 downto 0) := to_unsigned(integer(0.062*VAL_NB_BIT+0.5), NB_BIT_COEFF);
constant coeff_B_Cr    : unsigned(NB_BIT_COEFF-1 downto 0) := to_unsigned(integer(0.040*VAL_NB_BIT+0.5), NB_BIT_COEFF);
constant coeff_B_Cb    : unsigned(NB_BIT_COEFF-1 downto 0) := to_unsigned(integer(0.439*VAL_NB_BIT+0.5), NB_BIT_COEFF);

-- SIGNAL ---------------------------------------------------------------------------------------
signal R_dff      : unsigned(R'length-1 downto 0);
signal G_dff      : unsigned(G'length-1 downto 0);
signal B_dff      : unsigned(B'length-1 downto 0);

signal R_Y709     : unsigned(R'length+NB_BIT_COEFF-1 downto 0);
signal G_Y709     : unsigned(G'length+NB_BIT_COEFF-1 downto 0);
signal B_Y709     : unsigned(B'length+NB_BIT_COEFF-1 downto 0);
signal R_Cr       : unsigned(R'length+NB_BIT_COEFF-1 downto 0);
signal G_Cr       : unsigned(G'length+NB_BIT_COEFF-1 downto 0);
signal B_Cr       : unsigned(B'length+NB_BIT_COEFF-1 downto 0);
signal R_Cb       : unsigned(R'length+NB_BIT_COEFF-1 downto 0);
signal G_Cb       : unsigned(G'length+NB_BIT_COEFF-1 downto 0);
signal B_Cb       : unsigned(B'length+NB_BIT_COEFF-1 downto 0);

signal R_dff1     : unsigned(R'length-1 downto 0);
signal G_dff1     : unsigned(G'length-1 downto 0);
signal B_dff1     : unsigned(B'length-1 downto 0);

signal Y709       : unsigned(R'length-1 downto 0);
signal Cb         : unsigned(G'length-1 downto 0);
signal Cr         : unsigned(B'length-1 downto 0);

signal fval1      : std_logic := '0';
signal lval1      : std_logic := '0';
signal dval1      : std_logic := '0';
signal fval2      : std_logic := '0';
signal lval2      : std_logic := '0';
signal dval2      : std_logic := '0';

begin


    -- to use input register of DSP
    process(clk)
    begin
        if rising_edge(clk) then
            R_dff <= unsigned(R);
            G_dff <= unsigned(G);
            B_dff <= unsigned(B);
        end if;
    end process;

-- the 9 mult
    process(clk)
    begin
        if rising_edge(clk) then
            R_Y709 <= R_dff * coeff_R_Y709;
            R_Cr   <= R_dff * coeff_R_Cr;
            R_Cb   <= R_dff * coeff_R_Cb;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            G_Y709 <= G_dff * coeff_G_Y709;
            G_Cr   <= G_dff * coeff_G_Cr;
            G_Cb   <= G_dff * coeff_G_Cb;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            B_Y709 <= B_dff * coeff_B_Y709;
            B_Cr   <= B_dff * coeff_B_Cr;
            B_Cb   <= B_dff * coeff_B_Cb;
        end if;
    end process;

    -- for bypass
    process(clk)
    begin
        if rising_edge(clk) then
            R_dff1 <= R_dff;
            G_dff1 <= G_dff;
            B_dff1 <= B_dff;
        end if;
    end process;

-- final sum
process(clk)
begin
    if rising_edge(clk) then
        if (bypass = '0') then
            Y709 <= R_Y709(R_Y709'high downto R_Y709'high-Y709'length+1) + G_Y709(G_Y709'high downto G_Y709'high-Y709'length+1) + B_Y709(B_Y709'high downto B_Y709'high-Y709'length+1) + 64*4;
            Cr   <= ((512*4 + R_Cr(R_Cr'high downto R_Cr'high-Cr'length+1)) - G_Cr(G_Cr'high downto G_Cr'high-Cr'length+1)) - B_Cr(B_Cr'high downto B_Cr'high-Cr'length+1);
            Cb   <= ((512*4 + B_Cb(B_Cb'high downto B_Cb'high-Cb'length+1)) - G_Cb(G_Cb'high downto G_Cb'high-Cb'length+1)) - R_Cb(R_Cb'high downto R_Cb'high-Cb'length+1);
        else
            Y709 <= G_dff1;
            Cr   <= R_dff1;
            Cb   <= B_dff1;
        end if;
    end if;
end process;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Outputs

Y_o  <= std_logic_vector(Y709);
Cb_o <= std_logic_vector(Cb);
Cr_o <= std_logic_vector(Cr);

    -- latency
    process(clk)
    begin
        if rising_edge(clk) then
            fval1 <= fval;
            lval1 <= lval;
            dval1 <= dval;
            fval2 <= fval1;
            lval2 <= lval1;
            dval2 <= dval1;
            fval3 <= fval2;
            lval3 <= lval2;
            dval3 <= dval2;
        end if;
    end process;

end rtl;
