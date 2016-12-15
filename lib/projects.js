'use babel';

import ProjectsView from './projects-view';
import { CompositeDisposable } from 'atom';

export default {

  projectsView: null,
  modalPanel: null,
  subscriptions: null,

  activate(state) {
    this.projectsView = new ProjectsView(state.projectsViewState);
    this.modalPanel = atom.workspace.addModalPanel({
      item: this.projectsView.getElement(),
      visible: false
    });

    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable();

    // Register command that toggles this view
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'projects:toggle': () => this.toggle()
    }));
  },

  deactivate() {
    this.modalPanel.destroy();
    this.subscriptions.dispose();
    this.projectsView.destroy();
  },

  serialize() {
    return {
      projectsViewState: this.projectsView.serialize()
    };
  },

  toggle() {
    console.log('Projects was toggled!');
    return (
      this.modalPanel.isVisible() ?
      this.modalPanel.hide() :
      this.modalPanel.show()
    );
  }

};
