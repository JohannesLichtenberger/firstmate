import sys,time
case=sys.argv[1]
r='─'*109
bottom=r+'─'*10
top=r+' ↯ /fast ─'
rows={
'foreign-glyph':['─'*109+' ✳ /fast ─','❯',bottom],
'width-mismatch':[top+'─','❯',bottom],
'blank-continuation':[top,'❯ do not submit','',''+bottom],
'boxed-continuation':[top,'❯ do not submit','  │ transcript box │',bottom],
'unindented-transcript':[top,'❯','later transcript output',bottom],
'stale-envelope':[top,'❯',bottom,'later transcript output',bottom,'more output'],
}
print('\x1b[2J\x1b[H'+'\n'.join(rows[case]),flush=True)
time.sleep(90)
