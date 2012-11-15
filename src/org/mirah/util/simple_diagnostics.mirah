package org.mirah.util

import javax.tools.Diagnostic.Kind
import javax.tools.DiagnosticListener

class TooManyErrorsException; end

class SimpleDiagnostics implements DiagnosticListener
  def initialize(color:boolean)
    @errors = 0
    @newline = /\r?\n/
    if color
      @prefixes = {
        Kind.ERROR: '\e[1m\e[31mERROR\e[0m: ',
        Kind.MANDATORY_WARNING: '\e[1m\e[33mWARNING\e[0m: ',
        Kind.WARNING: '\e[1m\e[33mWARNING\e[0m: ',
        Kind.NOTE: '',
        Kind.OTHER: '',
      }
    else
      @prefixes = {
        Kind.ERROR: 'ERROR: ',
        Kind.MANDATORY_WARNING: 'WARNING: ',
        Kind.WARNING: 'WARNING: ',
        Kind.NOTE: '',
        Kind.OTHER: '',
      }
    end
  end
  
  def errorCount; @errors; end
  
  def report(diagnostic)
    @errors += 1 if Kind.ERROR == diagnostic.getKind
    source = CodeSource(diagnostic.getSource) if diagnostic.getSource.kind_of?(CodeSource)
    System.err.println("#{source.name}:#{diagnostic.getLineNumber}:") if source
    System.err.print(@prefixes[diagnostic.getKind])
    System.err.println(diagnostic.getMessage(null))
    if source
      target_line = diagnostic.getLineNumber - source.initialLine
      start_col = if target_line == 0
        diagnostic.getColumnNumber - source.initialColumn
      else
        diagnostic.getColumnNumber - 1
      end
      lines = source.contents.split(@newline)
      if target_line < lines.length
        line = lines[target_line]
        System.err.println(line)
        space = char[start_col]
        Arrays.fill(space, ? )
        System.err.print(space)
        length = Math.min(diagnostic.getEndPosition - diagnostic.getStartPosition,
                          line.length - start_col)
        underline = char[Math.max(length, 1)]
        Arrays.fill(underline, ?^)
        System.err.println(underline)
      end
    end
    raise TooManyErrorsException if @errors > 20
  end
end