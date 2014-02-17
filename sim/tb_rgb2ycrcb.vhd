------------------------------------------------------------------------
--  tb_rgb2ycrcb.vhd
--  testbench for rgb2ycrcb & yc422
--
--  Copyright (C) 2013 M.FORET
--
--  This program is free software: you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation, either version
--  2 of the License, or (at your option) any later version.
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;


entity testbench is
end entity;

architecture tb of testbench is

signal clk              : std_logic := '0';

signal R_in             : std_logic_vector(11  downto 0);
signal G_in             : std_logic_vector(11  downto 0);
signal B_in             : std_logic_vector(11  downto 0);

signal fval             : std_logic := '0';
signal lval             : std_logic := '0';
signal dval             : std_logic := '0';

signal Y_out            : std_logic_vector(11  downto 0);
signal Cr_out           : std_logic_vector(11  downto 0);
signal Cb_out           : std_logic_vector(11  downto 0);

signal fval2            : std_logic := '0';
signal lval2            : std_logic := '0';
signal dval2            : std_logic := '0';

signal Y_YC             : std_logic_vector(11  downto 0);
signal C_YC             : std_logic_vector(11  downto 0);

signal fval_out         : std_logic := '0';
signal lval_out         : std_logic := '0';
signal dval_out         : std_logic := '0';

begin

clk <= not(clk) after 5 ns;


process
    file line_txt            : text open read_mode is "./data_bench.txt";
    variable file_line       : line;

    procedure read_data is
        variable data            : integer;
    begin
      read(file_line, data);
      R_in <= std_logic_vector(to_unsigned(data, R_in'length));
      read(file_line, data);
      G_in <= std_logic_vector(to_unsigned(data, G_in'length));
      read(file_line, data);
      B_in <= std_logic_vector(to_unsigned(data, B_in'length));
    end;
begin

  fval <= '0';
  lval <= '0';
  dval <= '0';

  wait until rising_edge(clk);
  wait until rising_edge(clk);
  wait until rising_edge(clk);

  fval <= '1';
  lval <= '1';
  dval <= '1';

  while (not endfile(line_txt)) loop
    readline(line_txt, file_line);
    read_data;
    wait until rising_edge(clk);
  end loop;

  wait for 90 ns;

  wait until rising_edge(clk);
  R_in <= (others=>'0');
  G_in <= (others=>'0');
  B_in <= (others=>'0');
  wait until rising_edge(clk);

  fval <= '0';
  lval <= '0';
  dval <= '0';
  R_in <= (others=>'1');
  G_in <= (others=>'0');
  B_in <= (others=>'1');

  wait until rising_edge(clk);

  wait for 80 ns;

  report "End of test (this is not a failure)"
    severity failure;
  wait;

end process;


-- /////////////////////////////////////////////////////////////////////

rgb2ycrcb_inst : entity work.RGB2YCrCb
    port map (
      -- In -------------------------------------
      clk      => clk ,
      fval     => fval,
      lval     => lval,
      dval     => dval,
      R        => R_in,
      G        => G_in,
      B        => B_in,
      --
      bypass   => '0',
      -- Out -------------------------------------
      fval3    => fval2 ,
      lval3    => lval2 ,
      dval3    => dval2 ,
      Y_o      => Y_out ,
      Cb_o     => Cb_out,
      Cr_o     => Cr_out
    );

yc422_inst : entity work.yc422
  port map (
      -- In -------------------------------------
      clk    => clk   ,
      fval   => fval2 ,
      lval   => lval2 ,
      dval   => dval2 ,
      Y      => Y_out ,
      Cb     => Cb_out,
      Cr     => Cr_out,
      -- Out -------------------------------------
      fval2  => fval_out,
      lval2  => lval_out,
      dval2  => dval_out,
      Y_o    => Y_YC    ,
      C_o    => C_YC
    );

end tb;
