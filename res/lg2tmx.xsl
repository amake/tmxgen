<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- Convert Apple *.lg glossaries to TMX. Usage:
         xsltproc [-o <output file>] [-\-stringparam srclang <source lang>] lg2tmx.xsl <input file>
       If not specified, the TMX header's srclang attribute defaults to "*all*".
       Get glossaries at https://developer.apple.com/downloads/?name=glossaries -->
  <xsl:output method="xml" indent="yes" encoding="UTF-8" />
  <xsl:param name="srclang" select="'*all*'" />
  <xsl:template match="/">
    <tmx version="1.4">
      <header creationtool="lg2tmx" creationtoolversion="1.1"
              o-tmf="lg" adminlang="en" datatype="plaintext" segtype="paragraph">
        <xsl:attribute name="srclang">
          <xsl:value-of select="$srclang" />
        </xsl:attribute>
      </header>
      <body>
        <xsl:for-each select="Proj/File/TextItem[not(starts-with(TranslationSet/base, '{\rtf'))]">
          <tu>
            <xsl:attribute name="tuid">
              <xsl:value-of select="Position" />
            </xsl:attribute>
            <prop type="file"><xsl:value-of select="../Filepath" /></prop>
            <tuv>
              <xsl:attribute name="xml:lang">
                <xsl:value-of select="TranslationSet/base/@loc"/>
              </xsl:attribute>
              <seg><xsl:value-of select="TranslationSet/base" /></seg>
            </tuv>
            <tuv>
              <xsl:attribute name="xml:lang">
                <xsl:value-of select="TranslationSet/tran/@loc"/>
              </xsl:attribute>
              <seg><xsl:value-of select="TranslationSet/tran" /></seg>
            </tuv>
          </tu>
        </xsl:for-each>
      </body>
    </tmx>
  </xsl:template>
</xsl:stylesheet>
