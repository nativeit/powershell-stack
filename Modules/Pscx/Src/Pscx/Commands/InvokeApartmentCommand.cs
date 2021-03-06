using System;
using System.Management.Automation;
using System.Threading;
using System.Management.Automation.Runspaces;
using System.Collections.ObjectModel;

namespace Pscx.Commands
{
    [Cmdlet(PscxVerbs.Invoke, PscxNouns.Apartment)]
    [OutputType(new[]{typeof(PSObject[])})]
    public sealed class InvokeApartmentCommand : PscxCmdlet
    {
        private ApartmentState _apartment;
        private ScriptBlock _script;

        private Runspace _runspace;
        private Exception _exception;
        private Collection<PSObject> _results;

        [Parameter(Position = 0, Mandatory = true)]
        [ValidateSet("MTA", "STA")]
        public ApartmentState Apartment
        {
            get { return _apartment; }
            set { _apartment = value; }
        }

        [Parameter(Position = 1, Mandatory = true)]
        [ValidateNotNull]
        public ScriptBlock Expression
        {
            get { return _script; }
            set { _script = value; }
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();

            if (_apartment == Thread.CurrentThread.GetApartmentState())
            {
                WriteObject(_script.Invoke());
            }
            else
            {
                _runspace = Runspace.DefaultRunspace;

                Thread thread = new Thread(WorkerThread);
                thread.SetApartmentState(_apartment);

                thread.Start();
                thread.Join();

                if (_exception != null)
                {
                    IContainsErrorRecord errRecordContaier = (_exception as IContainsErrorRecord);

                    if (errRecordContaier != null)
                    {
                        ThrowTerminatingError(errRecordContaier.ErrorRecord);
                    }
                    else
                    {
                        ThrowTerminatingError(new ErrorRecord(_exception, _exception.GetType().Name, ErrorCategory.NotSpecified, null));
                    }
                }
                else
                {
                    WriteObject(_results, true);
                }
            }
        }

        private void WorkerThread()
        {
            Runspace.DefaultRunspace = _runspace;

            try
            {
                _results = _script.Invoke();
            }
            catch (Exception exc)
            {
                _exception = exc;
            }
        }
    }
}
