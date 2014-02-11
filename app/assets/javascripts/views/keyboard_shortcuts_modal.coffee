class @KeyboardShortcutsModal
  
  constructor: ->
    @template = '''
    <div class="modal hide" tabindex="-1">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h3>Keyboard Shortcuts</h3>
      </div>
      <div class="modal-body">
        <dl class="keyboard-shortcuts">
          <dt><span class="key">n</span> <span class="key">t</span></dt>
          <dd>New ticket</dd>
          <dt><span class="key">R</span> <span class="key">t</span></dt>
          <dd>Refresh tickets</dd>
          <dt><span class="key">?</span></dt>
          <dd>Keyboard shortcuts</dd>
        </dl>
      </div>
    </div>
    '''
  
  show: ->
    $modal = $(@template).modal()
    $modal.on 'hidden', -> $modal.remove()
