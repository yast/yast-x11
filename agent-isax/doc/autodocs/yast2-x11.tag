<?xml version='1.0' encoding='ISO-8859-1' standalone='yes'?>
<tagfile>
  <compound kind="file">
    <name>Xf86ConfigAgent.cc</name>
    <path>/opt/yast/source/x11/agent-isax/src/</path>
    <filename>Xf86ConfigAgent_8cc</filename>
    <includes id="Xf86ConfigAgent_8h" name="Xf86ConfigAgent.h" local="yes" imported="no">Xf86ConfigAgent.h</includes>
    <member kind="variable" static="yes">
      <type>static string</type>
      <name>glob_tmpdir</name>
      <anchor>a0</anchor>
      <arglist></arglist>
    </member>
    <member kind="variable" static="yes">
      <type>static string</type>
      <name>isax_log_path</name>
      <anchor>a1</anchor>
      <arglist></arglist>
    </member>
    <member kind="variable" static="yes">
      <type>static string</type>
      <name>rc_sax_path</name>
      <anchor>a2</anchor>
      <arglist></arglist>
    </member>
    <member kind="variable" static="yes">
      <type>static string</type>
      <name>xfree4_update_command</name>
      <anchor>a3</anchor>
      <arglist></arglist>
    </member>
  </compound>
  <compound kind="file">
    <name>Xf86ConfigAgent.h</name>
    <path>/opt/yast/source/x11/agent-isax/src/</path>
    <filename>Xf86ConfigAgent_8h</filename>
  </compound>
  <compound kind="file">
    <name>Y2CCXf86Config.cc</name>
    <path>/opt/yast/source/x11/agent-isax/src/</path>
    <filename>Y2CCXf86Config_8cc</filename>
    <includes id="Xf86ConfigAgent_8h" name="Xf86ConfigAgent.h" local="yes" imported="no">Xf86ConfigAgent.h</includes>
    <member kind="typedef">
      <type>Y2AgentComp&lt; Xf86ConfigAgent &gt;</type>
      <name>Y2Xf86ConfigAgentComp</name>
      <anchor>a0</anchor>
      <arglist></arglist>
    </member>
    <member kind="variable">
      <type>Y2CCAgentComp&lt; Y2Xf86ConfigAgentComp &gt;</type>
      <name>g_y2ccag_xf86config</name>
      <anchor>a1</anchor>
      <arglist>(&quot;ag_xf86config&quot;)</arglist>
    </member>
  </compound>
  <compound kind="struct">
    <name>ValueComment</name>
    <filename>structValueComment.html</filename>
    <member kind="variable">
      <type>string</type>
      <name>v</name>
      <anchor>o0</anchor>
      <arglist></arglist>
    </member>
    <member kind="variable">
      <type>string</type>
      <name>c</name>
      <anchor>o1</anchor>
      <arglist></arglist>
    </member>
  </compound>
  <compound kind="class">
    <name>Xf86ConfigAgent</name>
    <filename>classXf86ConfigAgent.html</filename>
    <base>SCRAgent</base>
    <member kind="function">
      <type></type>
      <name>Xf86ConfigAgent</name>
      <anchor>a0</anchor>
      <arglist>()</arglist>
    </member>
    <member kind="function">
      <type>YCPValue</type>
      <name>Read</name>
      <anchor>a1</anchor>
      <arglist>(const YCPPath &amp;path, const YCPValue &amp;arg=YCPNull(), const YCPValue &amp;opt=YCPNull())</arglist>
    </member>
    <member kind="function">
      <type>YCPBoolean</type>
      <name>Write</name>
      <anchor>a2</anchor>
      <arglist>(const YCPPath &amp;path, const YCPValue &amp;value, const YCPValue &amp;arg=YCPNull())</arglist>
    </member>
    <member kind="function">
      <type>YCPList</type>
      <name>Dir</name>
      <anchor>a3</anchor>
      <arglist>(const YCPPath &amp;path)</arglist>
    </member>
    <member kind="function" protection="private">
      <type>void</type>
      <name>init</name>
      <anchor>d0</anchor>
      <arglist>(void)</arglist>
    </member>
    <member kind="function" protection="private">
      <type>int</type>
      <name>shellCommand</name>
      <anchor>d1</anchor>
      <arglist>(const string command)</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPValue</type>
      <name>readYCPFile</name>
      <anchor>d2</anchor>
      <arglist>(const string ycp_file)</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPValue</type>
      <name>mergeMaps</name>
      <anchor>d3</anchor>
      <arglist>(YCPMap target, YCPMap source)</arglist>
    </member>
    <member kind="function" protection="private">
      <type>ValueComment</type>
      <name>getValueComment</name>
      <anchor>d4</anchor>
      <arglist>(const YCPMap config_map, const string key)</arglist>
    </member>
    <member kind="function" protection="private">
      <type>void</type>
      <name>writeKeyboardSection</name>
      <anchor>d5</anchor>
      <arglist>(const YCPMap &amp;config_map, FILE *file)</arglist>
    </member>
    <member kind="function" protection="private">
      <type>void</type>
      <name>writeMouseSection</name>
      <anchor>d6</anchor>
      <arglist>(const YCPMap &amp;config_map, FILE *file)</arglist>
    </member>
    <member kind="function" protection="private">
      <type>void</type>
      <name>writePathSection</name>
      <anchor>d7</anchor>
      <arglist>(const YCPMap &amp;config_map, FILE *file)</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPValue</type>
      <name>ReadAllXFree4</name>
      <anchor>d8</anchor>
      <arglist>(const YCPValue &amp;arg=YCPNull())</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPValue</type>
      <name>ReadXF86Config</name>
      <anchor>d9</anchor>
      <arglist>(const string section, const YCPValue &amp;arg=YCPNull())</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPValue</type>
      <name>ReadKeyboard</name>
      <anchor>d10</anchor>
      <arglist>(const YCPValue &amp;arg=YCPNull())</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPValue</type>
      <name>ReadMouse</name>
      <anchor>d11</anchor>
      <arglist>(const YCPValue &amp;arg=YCPNull())</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPValue</type>
      <name>ReadCard</name>
      <anchor>d12</anchor>
      <arglist>(const YCPValue &amp;arg=YCPNull())</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPValue</type>
      <name>ReadDesktop</name>
      <anchor>d13</anchor>
      <arglist>(const YCPValue &amp;arg=YCPNull())</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPValue</type>
      <name>ReadPath</name>
      <anchor>d14</anchor>
      <arglist>(const YCPValue &amp;arg=YCPNull())</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPValue</type>
      <name>ReadLayout</name>
      <anchor>d15</anchor>
      <arglist>(const YCPValue &amp;arg=YCPNull())</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPBoolean</type>
      <name>UpdateKeyboard</name>
      <anchor>d16</anchor>
      <arglist>(const YCPMap &amp;config_map, const YCPValue &amp;arg=YCPNull())</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPBoolean</type>
      <name>UpdateMouse</name>
      <anchor>d17</anchor>
      <arglist>(const YCPMap &amp;config_map, const YCPValue &amp;arg=YCPNull())</arglist>
    </member>
    <member kind="function" protection="private">
      <type>YCPBoolean</type>
      <name>UpdatePath</name>
      <anchor>d18</anchor>
      <arglist>(const YCPMap &amp;config_map, const YCPValue &amp;arg=YCPNull())</arglist>
    </member>
  </compound>
  <compound kind="dir">
    <name>/opt/yast/source/x11/agent-isax/src/</name>
    <path>/opt/yast/source/x11/agent-isax/src/</path>
    <filename>dir_000000.html</filename>
    <file>Xf86ConfigAgent.cc</file>
    <file>Xf86ConfigAgent.h</file>
    <file>Y2CCXf86Config.cc</file>
  </compound>
</tagfile>
